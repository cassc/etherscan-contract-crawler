// (c) Copyright 2022, Bad Pumpkin Inc. All Rights Reserved
//
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;

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

//
// Structs Related to Virtual Orders
////////////////////////////////////////////////////////////////////////////////

/// @notice Virtual Order details for a single user's Long-Term (LT) swap. An LT swap from
///         Token0 to Token1 is described as a user selling Token0 to the pool to buy Token1
///         from the pool.  Vice-versa if the swap is from Token1 to Token0.
/// @member token0To1 Swap direction, true swapping Token0 for Token1. False otherwise.
/// @member salesRate Amount of token sold to the pool per block for LT swap duration.
/// @member scaledProceedsAtSubmissionU128 The normalized proceeds of the pool for the token
///                                        being purchased at the block the order is
///                                        submitted. For example, for an LT swap of Token0
///                                        for Token1, this value would be the normalized
///                                        proceeds of Token1 for the pool. The normalized
///                                        value is also scaled for precision reasons.
///                                        Min. = 0, Max. = (2**128) - 1
/// @member owner The address issuing the LT swap virtual order; exclusively able to cancel or
///               withdraw the order.
/// @member delegate Is an address that is able to withdraw or cancel the LT swap on behalf
///                  of owner account, as long as the recipient specified is the owner
///                  account.
/// @member orderExpiry is the block in which this order expires.
struct Order {
  bool token0To1;
  uint112 salesRate;
  uint128 scaledProceedsAtSubmissionU128;
  address owner;
  address delegate;
  uint256 orderExpiry;
}

/// @notice This struct abstracts two order pools representing pooled Long-Term (LT) swaps in
///         each swap direction along with the current proceeds and a mapping of the sales
///         rate of each token at the end of a block. This allows the grouping of swaps in
///         the two swap directions for gas efficient execution when virutal orders are
///         executed. It is an adaptation of the staking algorithm desribed here:
///         - https://uploads-ssl.webflow.com/5ad71ffeb79acc67c8bcdaba/5ad8d1193a40977462982470_scalable-reward-distribution-paper.pdf
/// @member currentSalesRates stores the current sales rate of both Token0 and Token1 per block
///                           as 112-bit numbers packed into the 256-bit container. Token0
///                           occupies bits 224 downto 113 and Token1 bits 112 downto 1.
/// @member scaledProceeds stores the normalized, scaled, proceeds of each order pool together as
///                        128-bit numbers packed into the 256-bit container. Scaled proceeds0
///                        occupies bits 256 downto 129 and scaled proceeds1 occupies
///                        bits 128 downto 1.
///                        WARNING: Scaled proceeds0 and scaled proceeds1 described above are
///                        not the proceeds of Token0 and Token1 as would be expected, but rather
///                        the proceeds of order pool 0 and order pool 1 respectively. This means
///                        that scaled proceeds0 is actually the amount of Token1 obtained for
///                        users selling Token0 to the pool and vice-versa for proceeds1.
/// @member salesRateEndingPerBlock is a mapping of a block number to the sales rates of Token0
///                                 and Token1 expiring on that block number for each order pool.
///                                 The 112-bit sales rates are stored in a single 256-bit slot
///                                 together for efficiency. The sales rate for Token0 occupies
///                                 bits 224 downto 113 while the sales rate for Token1 occupies
///                                 bits 112 townto 1.
///
struct OrderPools {
  uint256 currentSalesRates;
  uint256 scaledProceeds;
  mapping(uint256 => uint256) salesRatesEndingPerBlock;
}

/// @notice This struct contains the order pool data for virtual orders comprising of sales of
///         Token0 for Token1 and vice-versa over multiple blocks. Each order pool is stored
///         herein, tracking the current sales rates and proceeds along with expiring sales
///         rates.
///         This struct also stores the scaled proceeds at each block, allowing an individual
///         user's proceeds to be calculated for a given interval. Each user's order is stored
///         with a mapping to their order id and the most recently executed virtual order block
///         and next order id are also stored herein.
/// @member orderPools is a struct containing the sale rate and proceeds for each of the two
///                    order pools along with expiring orders sales rates mapped by block.
/// @member scaledProceedsAtBlock is a mapping of a block number to the normalized, scaled,
///                               proceeds of each order pool together as 128-bit numbers packed
///                               into the 256-bit container. Scaled proceeds0 occupies
///                               bits 256 downto 129 and scaled proceeds1 occupies
///                               bits 128 downto 1.
///                               WARNING: Scaled proceeds0 and scaled proceeds1 described above are
///                               not the proceeds of Token0 and Token1 as would be expected, but rather
///                               the proceeds of order pool 0 and order pool 1 respectively. This means
///                               that scaled proceeds0 is actually the amount of Token1 obtained for
///                               users selling Token0 to the pool and vice-versa for proceeds1.
/// @dev The values contained in scaledProceedsAtBlock are always increasing and are expected to
///      overflow. Their difference when measured between two blocks, determines the proceeds in a
///      particular time-interval. A user's sales rate multiplying that amount determines the user's
///      share of the proceeds (scaledProceeds are normalized by the total sales rate and scaled up for
///      maintaining precision). The subtraction of the two points is also expected to underflow.
/// @member orderMap maps a particular order id to information about that order.
/// @member lastVirtualOrderBlock The ethereum block number before the last virtual orders were executed.
/// @member nextOrderId Is the next order id issued when a user places a Long-Term swap virtual order.
///
struct VirtualOrders {
  OrderPools orderPools;
  mapping(uint256 => uint256) scaledProceedsAtBlock;
  mapping(uint256 => Order) orderMap;
  uint256 lastVirtualOrderBlock;
  uint256 nextOrderId;
}

//
// Structs Related to Other Pool Features
////////////////////////////////////////////////////////////////////////////////

/// @notice The cumulative prices of Token0 and Token1 as of the start of the
///         last executed block (the timestamp of which can be fetched using
///         getOracleTimeStamp).
/// @member token0U256F112 The cumulative price of Token0 measured in amount of
///                        Token1 seconds.
/// @member token1U256F112 The cumulative price of Token1 measured in amount of
///                        Token0 seconds.
/// @dev These values have 112 fractional bits and are expected to overflow.
///      Behavior is identical to the price oracle introduced in Uniswap V2 with
///      similar limitations and vulnerabilities.
/// @dev The average price over an interval can be obtained by sampling these
///      values and their measurement times (see getOracleTimeStamp) and
///      computing the difference over the given interval.
struct PriceOracle {
  uint256 token0U256F112;
  uint256 token1U256F112;
}

//
// Structs for Gas Efficiency / Stack Depth Limitations
////////////////////////////////////////////////////////////////////////////////

/// @notice Struct for executing virtual orders across functions efficiently.
/// @member token0ReserveU112 reserves of Token0 in the TWAMM pool.
/// @member token1ReserveU112 reserves of Token1 in the TWAMM pool.
/// @member lpFeeU60 This is the portion of fees to be distributed to Liquidity Providers
///                  (LPs) after Balancer's portion is collected. The portioning is based
///                  on fractions of 10**18 and the value is computed by subtracting
///                  Balancer's portion from 10**18. If Cron-Fi fees are being collected
///                  this value is used to compute the fee share, feeShareU60.
/// @member feeShareU60 If Cron-Fi fees are being collected, this amount represents a
///                     single share of the fees remaining after Balancer's portion. A
///                     single share goes to Cron-Fi and multiples of a single share go
///                     to the Liquidity Providers (LPs) based on the fee shift value,
///                     feeShiftU3.
/// @member feeShiftU3 If Cron-Fi fees are being collected, this represents the amount of
///                    bits shifted to partition fees between Liquidity Providers (LPs)
///                    and Cron-Fi. For example, if this is 1, then 2 shares of fees
///                    collected after Balancer's portion go to the LPs and 1 share goes
///                    to Cron-Fi. If it is 2, then 4 shares go to the LPs and 1 share
///                    goes to Cron-Fi.
/// @member orderPool0ProceedsScaling is the amount to scale proceeds of order pool 0 (Long-
///                                   Term swaps of Token 0 to Token 1) based on the number
///                                   of decimal places in Token 0.
/// @member orderPool0ProceedsScaling is the amount to scale proceeds of order pool 1 (Long-
///                                   Term swaps of Token 1 to Token 0) based on the number
///                                   of decimal places in Token 1.
/// @member token0BalancerFeesU96 Balancer fees collected for Token0-->Token1 swaps.
/// @member token1BalancerFeesU96 Balancer fees collected for Token1-->Token0 swaps.
/// @member token0CronFiFeesU96 Cron-Fi fees collected for Token0-->Token1 Long-Term swaps.
/// @member token1CronFiFeesU96 Cron-Fi fees collected for Token1-->Token0 Long-Term swaps.
/// @member token0OrdersU112 Amount of Token0 sold to the pool in virtual orders.
/// @member token1OrdersU112 Amount of Token1 sold to the pool in virtual orders.
/// @member token0ProceedsU112 Amount of Token0 bought from the pool in virtual orders.
/// @member token1ProceedsU112 Amount of Token1 bought from the pool in virtual orders.
/// @member token0OracleU256F112 The computed increment for the price oracle for Token 0.
/// @member token1OracleU256F112 The computed increment for the price oracle for Token 1.
/// @member oracleTimeStampU32 The oracle time stamp.
///
struct ExecVirtualOrdersMem {
  uint256 token0ReserveU112;
  uint256 token1ReserveU112;
  uint256 lpFeeU60;
  uint256 feeShareU60;
  uint256 feeShiftU3;
  uint256 token0BalancerFeesU96;
  uint256 token1BalancerFeesU96;
  uint256 token0CronFiFeesU96;
  uint256 token1CronFiFeesU96;
  uint256 token0OrdersU112;
  uint256 token1OrdersU112;
  uint256 token0ProceedsU112;
  uint256 token1ProceedsU112;
  uint256 token0OracleU256F112;
  uint256 token1OracleU256F112;
}

/// @notice Struct for executing the virtual order loop efficiently (reduce
///         storage reads/writes). Advantages increase when pool is inactive
///         for longer multiples of the Order Block Interval.
/// @member lastVirtualOrderBlock The ethereum block number before the last virtual orders were
///                               executed.
/// @member scaledProceeds0U128 The normalized scaled proceeds of order pool 0 in Token1. For
///                             example, for an LT swap of Token0 for Token1, this value
///                             would be the normalized proceeds of Token1 for the pool. The
///                             normalized value is also scaled for precision reasons.
///                             Min. = 0, Max. = (2**128) - 1
/// @member scaledProceeds1U128 The normalized scaled proceeds of order pool 1 in Token0.
///                             Min. = 0, Max. = (2**128) - 1
/// @member currentSalesRate0U112 The current sales rate of Token0 per block.
///                               Min. = 0, Max. = (2**112) - 1
/// @member currentSalesRate1U112 The current sales rate of Token1 per block.
///                               Min. = 0, Max. = (2**112) - 1
///
struct LoopMem {
  // Block Numbers:
  uint256 lastVirtualOrderBlock;
  // Order Pool Items:
  uint256 scaledProceeds0U128;
  uint256 scaledProceeds1U128;
  uint256 currentSalesRate0U112;
  uint256 currentSalesRate1U112;
}