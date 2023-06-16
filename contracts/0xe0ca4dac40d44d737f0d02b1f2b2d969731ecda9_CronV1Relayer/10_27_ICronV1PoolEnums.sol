// (c) Copyright 2022, Bad Pumpkin Inc. All Rights Reserved
//
// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.6;

interface ICronV1PoolEnums {
  /// @notice Enumeration for the type of TWAMM pool created; the type determines the default fees and the immutable block
  ///         interval that the pool will operate with for it's lifetime. Each enumeration value is described in more
  ///         detail below (Fee Points = FP):
  ///
  ///           Stable:
  ///
  ///             - Intended for pool tokens that trade frequently; features lower fees and more frequent Long-Term order
  ///               expiries in exchange for higher gas use.
  ///             Short-Term Swap Fee  = 10 FP (0.010%)
  ///             Arbitrageur Swap Fee =  5 FP (0.005%)
  ///             Long-Term Swap Fee   = 30 FP (0.030%)
  ///             Order Block Interval = 75 blocks (~15 minutes)
  ///
  ///           Liquid:
  ///
  ///             - The middle ground setting between tokens that trade frequently and those that trade infrequently with
  ///               low-liquidity. Mid-range fees and order expiry frequency.
  ///             Short-Term Swap Fee  =  50 FP (0.050%)
  ///             Arbitrageur Swap Fee =  25 FP (0.025%)
  ///             Long-Term Swap Fee   = 150 FP (0.150%)
  ///             Order Block Interval = 300 blocks (~1 hour)
  ///
  ///           Volatile:
  ///
  ///             - Intended for pool tokens that trade infrequently with low-liquidity; features higher fees and less
  ///               frequent Long-Term order expiries in exchange for reduced gas use.
  ///             Short-Term Swap Fee  = 100 FP (0.100%)
  ///             Arbitrageur Swap Fee =  50 FP (0.050%)
  ///             Long-Term Swap Fee   = 300 FP (0.300%)
  ///             Order Block Interval = 1200 blocks (~ 4 hours)
  ///
  enum PoolType {
    Stable, // 0
    Liquid, // 1
    Volatile // 2
  }

  /// @notice Enumeration for functionality when joining the pool:
  ///         - Join performs the standard Join/Mint functionality, taking the provided tokens in exchange for
  ///           pool Liquidity Provider (LP) tokens.
  ///         - Reward performs a donation of the provided tokens to the pool with no LP tokens provided in return.
  ///
  enum JoinType {
    Join, // 0
    Reward // 1
  }

  /// @notice Enumeration for functionality when swapping with the pool:
  ///         - RegularSwap performs a standard swap of the specified token for its opposing token using the Constant
  ///           Product Automated Market Maker (CPAMM) formula.
  ///         - LongTermSwap performs a swap of the spcified token for its opposing token over more than one block.
  ///         - PartnerSwap performs a reduced fee RegularSwap with registered arbitrage partner's arbitrageurs.
  ///
  enum SwapType {
    RegularSwap, // 0
    LongTermSwap, // 1
    PartnerSwap // 2
  }

  /// @notice Enumeration for functionality when exiting the pool:
  ///         - Exit performs a standard exit or burn functionality, taking provided LP tokens in exchange for the
  ///           proportional amount of pool tokens.
  ///         - Withdraw performs a Long-Term swap order proceeds withdrawl.
  ///         - Cancel performs a Long-Term swap order cancellation, remitting proceeds and refunding unspent deposits.
  ///         - FeeWithdraw performs a withdraw of Cron-Fi fees to the fee address if enabled.
  ///
  enum ExitType {
    Exit, // 0
    Withdraw, // 1
    Cancel, // 2
    FeeWithdraw // 3
  }

  /// @notice Enumeration for shared parameterization setting function to specify parameter being set:
  ///         - SwapFeeFP is the short term swap fee in Fee Points (FP).
  ///         - PartnerFeeFP is the arbitrage partner swap fee in FP.
  ///         - LongSwapFeeFP is the Long-Term swap fee in FP.
  /// @dev NOTE: Total FP = 100,000. Thus a fee portion is the number of FP out of 100,000.
  ///
  enum ParamType {
    // Slot 1:
    SwapFeeFP, // 0
    PartnerFeeFP, // 1
    LongSwapFeeFP // 2
  }

  /// @notice Enumeration for shared event log for boolean parameter state changes. The event
  ///         BoolParameterChange will contain one of the following enum values to indicate a
  ///         change to the respective one--the pool's paused state or collection of balancer fees.
  ///
  enum BoolParamType {
    Paused, // 0
    CollectBalancerFees // 1
  }
}