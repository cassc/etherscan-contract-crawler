// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// common
error Unauthorized();
error Overflow();
error BadAddress();

// BaseVault
error BV_ActiveRound();
error BV_BadCollateral();
error BV_BadExpiry();
error BV_BadLevRatio();
error BV_ExpiryMismatch();
error BV_MarginEngineMismatch();
error BV_RoundClosed();
error BV_BadFee();
error BV_BadRoundConfig();
error BV_BadDepositAmount();
error BV_BadAmount();
error BV_BadRound();
error BV_BadNumShares();
error BV_ExceedsAvailable();
error BV_BadPPS();
error BV_BadSB();
error BV_BadCP();
error BV_BadRatios();

// OptionsVault
error OV_ActiveRound();
error OV_BadRound();
error OV_BadCollateral();
error OV_RoundClosed();
error OV_OptionNotExpired();
error OV_NoCollateralPending();
error OV_VaultExercised();

// PhysicalOptionVault
error POV_CannotRequestWithdraw();
error POV_NotExercised();
error POV_NoCollateral();
error POV_OptionNotExpired();
error POV_BadExerciseWindow();

// Fee Utils
error FL_NPSLow();

// Vault Utils
error VL_DifferentLengths();
error VL_ExceedsSurplus();
error VL_BadOwnerAddress();
error VL_BadManagerAddress();
error VL_BadFeeAddress();
error VL_BadOracleAddress();
error VL_BadPauserAddress();
error VL_BadFee();
error VL_BadCollateral();
error VL_BadCollateralAddress();
error VL_BadDuration();

// StructureLib
error SL_BadExpiryDate();

// Vault Pauser
error VP_VaultNotPermissioned();
error VP_PositionPaused();
error VP_Overflow();
error VP_CustomerNotPermissioned();
error VP_RoundOpen();

// Vault Share
error VS_SupplyExceeded();

// Whitelist Manager
error WL_BadRole();
error WL_Paused();