// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title ConfigOptions
 * @notice A central place for enumerating the configurable options of our AlloyxConfig contract
 * @author AlloyX
 */

library ConfigOptions {
  // NEVER EVER CHANGE THE ORDER OF THESE!
  // You can rename or append. But NEVER chan ge the order.
  enum Booleans {
    IsPaused
  }
  enum Numbers {
    InflationPerYearForProtocolFee, // In 4 decimals, where 100 means 1%
    RegularStakerProportion, // In 4 decimals, where 100 means 1%
    PermanentStakerProportion, // In 4 decimals, where 100 means 1%
    MinDelay,
    QuorumPercentage,
    VotingPeriod,
    VotingDelay,
    ThresholdAlyxForVaultCreation,
    ThresholdUsdcForVaultCreation,
    UniswapFeeBasePoint
  }
  enum Addresses {
    Manager,
    ALYX,
    Treasury,
    PermanentStakeInfo,
    RegularStakeInfo,
    Config,
    StakeDesk,
    GoldfinchDesk,
    TruefiDesk,
    MapleDesk,
    ClearPoolDesk,
    RibbonDesk,
    RibbonLendDesk,
    CredixDesk,
    CredixOracle,
    Whitelist,
    BackerRewards,
    PoolTokens,
    SeniorPool,
    FIDU,
    GFI,
    USDC,
    MPL,
    WETH,
    SwapRouter,
    Operator,
    FluxToken,
    FluxDesk,
    BackedDesk,
    BackedOracle,
    BackedToken,
    WalletDesk,
    OpenEdenDesk,
    AlloyxV1Desk,
    AlloyxV1StableCoinDesk,
    AlloyxV1Exchange,
    AlloyxV1Dura
  }
}