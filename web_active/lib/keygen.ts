import crypto from 'crypto';

export interface TokenConfigParams {
  deviceSnMd5: string;
  characterUid: string;
  durationDays: number;
  expireAtUnix: number; // Unix timestamp in seconds
  fovMin: number;
  fovMax: number;
  bossRefreshMin: number;
  bossRefreshMax: number;
  maxMoveSpeed: number;
  maxAttackSpeed: number;
  maxMonsterRange: number;
  maxPickupCount: number;
  pickupDelayMin: number;
  pickupDelayMax: number;
  activeTabBasic: boolean;
  activeTabAdvanced: boolean;
  activeTabAutofarm: boolean;
  characterReincarnation: number;
  characterReincarnationSecondary?: number;
  adminTelegrams: string[];
}

export function generateEncryptedToken(params: TokenConfigParams): { jsonConfig: string; signature: string; encryptedToken: string } {
  const configObject = {
    device_sn_hash: params.deviceSnMd5.trim(),
    character_uid: params.characterUid.trim(),
    duration: `${params.durationDays}d`,
    expire_time: params.expireAtUnix,
    fov_min: Number(params.fovMin),
    fov_max: Number(params.fovMax),
    boss_refresh_min: Number(params.bossRefreshMin),
    boss_refresh_max: Number(params.bossRefreshMax),
    max_move_speed: Number(params.maxMoveSpeed),
    max_attack_speed: Number(params.maxAttackSpeed),
    max_monster_range: Number(params.maxMonsterRange),
    max_pickup_count: Number(params.maxPickupCount),
    pickup_delay_min: Number(params.pickupDelayMin ?? 100),
    pickup_delay_max: Number(params.pickupDelayMax ?? 500),
    active_tab_basic: Boolean(params.activeTabBasic),
    active_tab_advanced: Boolean(params.activeTabAdvanced),
    active_tab_autofarm: Boolean(params.activeTabAutofarm),
    character_reincarnation: Number(params.characterReincarnation),
    character_reincarnation_primary: Number(params.characterReincarnation),
    character_reincarnation_secondary: Number(params.characterReincarnationSecondary ?? (params.characterReincarnation - 1)),
    admin_telegrams: Array.isArray(params.adminTelegrams) ? params.adminTelegrams : ["@admin1", "@admin2"],
  };

  const jsonConfig = JSON.stringify(configObject);
  const secretSalt = process.env.MOD_SECRET_SALT || "MUVH_SECRET_SALT_XOAI";
  
  // MD5 signature of JSON + SALT
  const signature = crypto.createHash('md5').update(jsonConfig + secretSalt).digest('hex');
  
  // Final payload envelope: JSON|SIGNATURE -> Base64
  const envelope = `${jsonConfig}|${signature}`;
  const encryptedToken = Buffer.from(envelope, 'utf-8').toString('base64');

  return {
    jsonConfig,
    signature,
    encryptedToken,
  };
}

export function decryptAndVerifyToken(base64Token: string): { valid: boolean; config?: any; error?: string } {
  try {
    const envelope = Buffer.from(base64Token, 'base64').toString('utf-8');
    const lastPipeIndex = envelope.lastIndexOf('|');
    if (lastPipeIndex === -1) {
      return { valid: false, error: 'Invalid token format' };
    }

    const jsonConfig = envelope.substring(0, lastPipeIndex);
    const signature = envelope.substring(lastPipeIndex + 1);

    const secretSalt = process.env.MOD_SECRET_SALT || "MUVH_SECRET_SALT_XOAI";
    const expectedSig = crypto.createHash('md5').update(jsonConfig + secretSalt).digest('hex');

    if (signature.toLowerCase() !== expectedSig.toLowerCase()) {
      return { valid: false, error: 'Token signature tampered or invalid' };
    }

    const config = JSON.parse(jsonConfig);
    return { valid: true, config };
  } catch (err: any) {
    return { valid: false, error: err.message || 'Token decryption failed' };
  }
}

// =========================================================================
// [MOD FEATURE]: TẠO TOKEN SVIP THEO QUY TẮC KEYGEN.PS1
// Mô tả: Đóng gói chuỗi "$DeviceCode|$UID|$MainTier|$SubTier|$Duration|$unixTime"
//        Ký MD5 với MUVH_SECRET_SALT_XOAI và Base64 Encode
// =========================================================================

export interface SvipTokenConfigParams {
  deviceSnMd5: string;
  characterUid: string;
  mainTier?: number;
  subTier?: number;
  durationDays: number;
  startTimeUnix: number; // Unix timestamp in seconds
}

export function generateSvipEncryptedToken(params: SvipTokenConfigParams): { tokenData: string; signature: string; encryptedToken: string } {
  const devCode = params.deviceSnMd5.trim();
  const uid = params.characterUid.trim();
  const main = Number(params.mainTier) || 8;
  const sub = Number(params.subTier) || 7;
  const dur = Number(params.durationDays);
  const durStr = dur === 0.000694444 ? "0.000694444" : String(dur);
  const time = Math.floor(params.startTimeUnix);

  const tokenData = `${devCode}|${uid}|${main}|${sub}|${durStr}|${time}`;
  const secretSalt = process.env.MOD_SECRET_SALT || "MUVH_SECRET_SALT_XOAI";
  
  // MD5 signature of tokenData + secretSalt (no pipe between unixTime and salt)
  const signature = crypto.createHash('md5').update(tokenData + secretSalt).digest('hex').toLowerCase();
  
  const finalString = `${tokenData}|${signature}`;
  const encryptedToken = Buffer.from(finalString, 'utf-8').toString('base64');

  return {
    tokenData,
    signature,
    encryptedToken,
  };
}

export function decryptAndVerifySvipToken(base64Token: string): { valid: boolean; data?: any; error?: string } {
  try {
    const decoded = Buffer.from(base64Token, 'base64').toString('utf-8');
    const parts = decoded.split('|');
    if (parts.length < 7) {
      return { valid: false, error: 'Định dạng Token SVIP không hợp lệ' };
    }

    const [deviceCode, uid, mainTier, subTier, duration, startTime, signature] = parts;
    const tokenData = `${deviceCode}|${uid}|${mainTier}|${subTier}|${duration}|${startTime}`;
    const secretSalt = process.env.MOD_SECRET_SALT || "MUVH_SECRET_SALT_XOAI";
    const expectedSig = crypto.createHash('md5').update(tokenData + secretSalt).digest('hex').toLowerCase();

    if (signature.toLowerCase() !== expectedSig) {
      return { valid: false, error: 'Chữ ký Token không hợp lệ' };
    }

    return {
      valid: true,
      data: {
        deviceCode,
        uid,
        mainTier: Number(mainTier),
        subTier: Number(subTier),
        duration: Number(duration),
        startTime: Number(startTime),
      },
    };
  } catch (err: any) {
    return { valid: false, error: err.message || 'Giải mã Token thất bại' };
  }
}

