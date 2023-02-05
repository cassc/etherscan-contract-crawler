// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// common
error Unauthorized();
error Overflow();

// Vault
error HV_ActiveRound();
error HV_AuctionInProgress();
error HV_BadAddress();
error HV_BadAmount();
error HV_BadCap();
error HV_BadCollaterals();
error HV_BadCollateralPosition();
error HV_BadDepositAmount();
error HV_BadDuration();
error HV_BadExpiry();
error HV_BadFee();
error HV_BadLevRatio();
error HV_BadNumRounds();
error HV_BadNumShares();
error HV_BadNumStrikes();
error HV_BadOption();
error HV_BadPPS();
error HV_BadRound();
error HV_BadRoundConfig();
error HV_BadSB();
error HV_BadStructures();
error HV_CustomerNotPermissioned();
error HV_ExistingWithdraw();
error HV_ExceedsCap();
error HV_ExceedsAvailable();
error HV_Initialized();
error HV_InsufficientFunds();
error HV_OptionNotExpired();
error HV_RoundClosed();
error HV_RoundNotClosed();
error HV_Unauthorized();
error HV_Uninitialized();

// VaultPauser
error VP_BadAddress();
error VP_CustomerNotPermissioned();
error VP_Overflow();
error VP_PositionPaused();
error VP_RoundOpen();
error VP_Unauthorized();
error VP_VaultNotPermissioned();

// VaultUtil
error VL_BadCap();
error VL_BadCollateral();
error VL_BadCollateralAddress();
error VL_BadDuration();
error VL_BadExpiryDate();
error VL_BadFee();
error VL_BadFeeAddress();
error VL_BadId();
error VL_BadInstruments();
error VL_BadManagerAddress();
error VL_BadOracleAddress();
error VL_BadOwnerAddress();
error VL_BadPauserAddress();
error VL_BadPrecision();
error VL_BadStrikeAddress();
error VL_BadSupply();
error VL_BadUnderlyingAddress();
error VL_BadWeight();
error VL_DifferentLengths();
error VL_ExceedsSurplus();
error VL_Overflow();
error VL_Unauthorized();

// FeeUtil
error FU_NPSLow();

// BatchAuction
error BA_AuctionClosed();
error BA_AuctionNotClosed();
error BA_AuctionSettled();
error BA_AuctionUnsettled();
error BA_BadAddress();
error BA_BadAmount();
error BA_BadBiddingAddress();
error BA_BadCollateral();
error BA_BadOptionAddress();
error BA_BadOptions();
error BA_BadPrice();
error BA_BadSize();
error BA_BadTime();
error BA_EmptyAuction();
error BA_Unauthorized();
error BA_Uninitialized();

// Whitelist
error WL_BadAddress();
error WL_BadRole();
error WL_Paused();
error WL_Unauthorized();

// VaultShare
error VS_SupplyExceeded();