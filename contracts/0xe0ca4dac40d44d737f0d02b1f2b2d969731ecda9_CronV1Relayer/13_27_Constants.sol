// (c) Copyright 2023, Bad Pumpkin Inc. All Rights Reserved
//
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;

/// @notice Library of constants used throughout the implementation.
///
/// @dev Conventions in the methods, variables and constants are as follows:
///
///      Prefixes:
///
///      - In constants, the prefix "Sn", where 1 <= n <= 4, denotes which slot the constant
///        pertains too. There are four storage slots that are bitpacked. For example,
///        "S2_OFFSET_ORACLE_TIMESTAMP" refers to the offset of the oracle timestamp in bit-
///        packed storage slot 2.
///
///      Suffixes:
///
///      - The suffix of a variable name denotes the type contained within the variable.
///        For instance "uint256 _incrementU96" is a 256-bit unsigned container representing
///        the 96-bit value "_increment".
///        In the case of "uint256 _balancerFeeDU1F18", the 256-bit unsigned container is
///        representing a 19 digit decimal value with 18 fractional digits. In this scenario,
///        the D=Decimal, U=Unsigned, F=Fractional.
///        Finally, "uint128 valueU128F64" is a 128-bit container representing a 128-bit value
///        with 64 fractional bits.
///
///      - The suffix of a function name denotes what slot it is proprietary too as a
///        matter of convention. While unchecked at run-time or by the compiler, the naming
///        convention easily aids in understanding what slot a packed value is stored within.
///        For instance the function "unpackFeeShiftS3" unpacks the fee shift from slot 3. If
///        the value of slot 2 were passed to this method, the unpacked value would be
///        incorrect.
///
library C {
  //
  // Factory owner and default pool admin address
  ////////////////////////////////////////////////////////////////////////////////
  address internal constant CRON_DEPLOYER_ADMIN = 0xe122Eff60083bC550ACbf31E7d8197A58d436b39;

  //
  // General constants
  ////////////////////////////////////////////////////////////////////////////////
  address internal constant NULL_ADDR = address(0);

  uint256 internal constant FALSE = 0;

  uint256 internal constant MAX_U256 = type(uint256).max;
  uint256 internal constant MAX_U128 = type(uint128).max;
  uint256 internal constant MAX_U112 = type(uint112).max;
  uint256 internal constant MAX_U96 = type(uint96).max;
  uint256 internal constant MAX_U64 = type(uint64).max;
  uint256 internal constant MAX_U60 = 2**60 - 1;
  uint256 internal constant MAX_U32 = type(uint32).max;
  uint256 internal constant MAX_U24 = type(uint24).max;
  uint256 internal constant MAX_U20 = 0xFFFFF;
  uint256 internal constant MAX_U16 = type(uint16).max;
  uint256 internal constant MAX_U10 = 0x3FF;
  uint256 internal constant MAX_U8 = type(uint8).max;
  uint256 internal constant MAX_U3 = 0x7;
  uint256 internal constant MAX_U1 = 0x1;

  uint256 internal constant ONE_DU1_18 = 10**18;
  uint256 internal constant DENOMINATOR_DU1_18 = 10**18;

  uint256 internal constant SECONDS_PER_BLOCK = 12;

  //
  // Array Index constants
  ////////////////////////////////////////////////////////////////////////////////
  uint256 internal constant INDEX_TOKEN0 = 0;
  uint256 internal constant INDEX_TOKEN1 = 1;

  //
  // Bit-Packing constants
  //
  // Dev: Bit-offsets below are the offset from the first bit. For example to get
  //      to bit 250, the offset 249 is used. (The first bit is counted as bit 1).
  ////////////////////////////////////////////////////////////////////////////////

  // Masks:
  uint256 internal constant CLEAR_MASK_PAIR_U96 = ~((MAX_U96 << 96) | MAX_U96);
  uint256 internal constant CLEAR_MASK_PAIR_U112 = ~((MAX_U112 << 112) | MAX_U112);
  uint256 internal constant CLEAR_MASK_ORACLE_TIMESTAMP = ~(MAX_U32 << S2_OFFSET_ORACLE_TIMESTAMP);
  uint256 internal constant CLEAR_MASK_FEE_SHIFT = ~(MAX_U3 << S3_OFFSET_FEE_SHIFT_U3);
  uint256 internal constant CLEAR_MASK_BALANCER_FEE = ~(MAX_U60 << S4_OFFSET_BALANCER_FEE);

  // Slot 1 Offsets:
  uint256 internal constant S1_OFFSET_SHORT_TERM_FEE_FP = 244; // Bits 254-245;
  uint256 internal constant S1_OFFSET_PARTNER_FEE_FP = 234; // Bits 244-235;
  uint256 internal constant S1_OFFSET_LONG_TERM_FEE_FP = 224; // Bits 234-225;

  // Slot 2 Offsets:
  uint256 internal constant S2_OFFSET_ORACLE_TIMESTAMP = 224; // Bits 256-225;

  // Slot 3 Offsets:
  uint256 internal constant S3_OFFSET_FEE_SHIFT_U3 = 222; // Bits 225-223

  // Slot 4 Offsets:
  uint256 internal constant S4_OFFSET_PAUSE = 255; // Bit 256
  uint256 internal constant S4_OFFSET_CRON_FEE_ENABLED = 254; // Bit 255
  uint256 internal constant S4_OFFSET_COLLECT_BALANCER_FEES = 253; // Bit 254
  uint256 internal constant S4_OFFSET_ZERO_CRONFI_FEES = 252; // Bit 253
  uint256 internal constant S4_OFFSET_BALANCER_FEE = 192; // Bits 252-193;

  //
  // Scaling constants
  ////////////////////////////////////////////////////////////////////////////////
  //
  uint256 internal constant MAX_DECIMALS = 22;
  uint256 internal constant MIN_DECIMALS = 2;

  //
  // Pool Specific constants
  ////////////////////////////////////////////////////////////////////////////////
  uint256 internal constant MINIMUM_LIQUIDITY = 10**3;

  uint16 internal constant STABLE_OBI = 75; // ~15m @ 12s/block
  uint16 internal constant LIQUID_OBI = 300; // ~60m @ 12s/block
  uint16 internal constant VOLATILE_OBI = 1200; // ~240m @ 12s/block

  // Maximum long-term swap (5 years, 13149000 blocks @ 12s/block).
  // - Numbers below are 13149000 / OBI (rounded down where noted):
  uint24 internal constant STABLE_MAX_INTERVALS = 175320;
  uint24 internal constant LIQUID_MAX_INTERVALS = 43830;
  uint24 internal constant VOLATILE_MAX_INTERVALS = 10957; // Rounded down from 10957.5

  //
  // Fees constants
  ////////////////////////////////////////////////////////////////////////////////
  //       FP = Total Fee Points
  //       ST = Short-Term Swap
  //       LT = Long-Term Swap
  //       LP = Liquidity Provider
  //       CF = Cron Fi
  //
  // NOTE: Mult-by these constants requires Max. 14-bits (~13.3 bits) headroom to prevent overflow.
  //
  uint256 internal constant TOTAL_FP = 100000;
  uint256 internal constant MAX_FEE_FP = 1000; // 1.000%

  // Short Term Swap Payouts:
  // ----------------------------------------
  uint16 internal constant STABLE_ST_FEE_FP = 10; // 0.010%
  uint16 internal constant LIQUID_ST_FEE_FP = 50; // 0.050%
  uint16 internal constant VOLATILE_ST_FEE_FP = 100; // 0.100%

  // Partner Swap Payouts:
  // ----------------------------------------
  uint16 internal constant STABLE_ST_PARTNER_FEE_FP = 5; // 0.005%
  uint16 internal constant LIQUID_ST_PARTNER_FEE_FP = 25; // 0.025%
  uint16 internal constant VOLATILE_ST_PARTNER_FEE_FP = 50; // 0.050%

  // Long Term Swap Payouts
  // ----------------------------------------
  uint16 internal constant STABLE_LT_FEE_FP = 30; // 0.030%
  uint16 internal constant LIQUID_LT_FEE_FP = 150; // 0.150%
  uint16 internal constant VOLATILE_LT_FEE_FP = 300; // 0.300%

  uint8 internal constant DEFAULT_FEE_SHIFT = 1; // 66% LP to 33% CronFi
}