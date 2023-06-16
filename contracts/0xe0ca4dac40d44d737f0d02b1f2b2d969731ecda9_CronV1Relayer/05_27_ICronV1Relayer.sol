// SPDX-License-Identifier: BUSL-1.1

// (c) Copyright 2023, Bad Pumpkin Inc. All Rights Reserved
//

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import { IVault } from "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import { Order } from "../interfaces/Structs.sol";

/// @title ICronV1Relayer
/// @notice Provides a simplified interface to Cron-Finance Time Weighted Average Market Maker (TWAMM) pools impelemnted
///         in the Balancer Vault, performing additional safety and usability checks along the way.
///
///         IMPORTANT: pool addresses and ids for all calls are determined by the Cron-Finance TWAMM Factory contract,
///                    preventing access to other types of pools in the Balancer Vault for additional safety.
///
interface ICronV1Relayer {
  /// @notice Performs a short-term (atomic) swap of the specified amount of token in to token out on the Cron- Finance
  ///         Time-Weighted Average Market Maker (TWAMM) pool uniquely identified from the addresses of token in, token
  ///         out, and the pool type.
  ///
  ///         The slippage specified in basis points is used to determine how much token out can be lost relative
  ///         to a trade occuring at the current reserve ratio. If the amount of token out is more than the slippage
  ///         percent different than the ideal amount calculated by the current reserve ratio, the trade reverts.
  ///
  ///         A recipient can be specified if the proceeds of the trade are to be directed to an account different
  ///         from the calling account, msg.sender.
  ///
  ///         IMPORTANT: Users must approve this contract on the Balancer Vault before any transactions can be used.
  ///                    This can be done by calling setRelayerApproval on the Balancer Vault contract and specifying
  ///                    this contract's address.
  ///
  ///         Checks performed on behalf of a user include:
  ///           - Pool specified by token in and out addresses and pool type exists.
  ///           - Pool has been funded and contains minimum liquidity amounts.
  ///           - Swap amount specified is greater than zero and available in the calling account (msg.sender).
  ///           - Trade results in amount of token out within specified slippage percent of the ideal amount
  ///             calculated from the ratio of the pool's virtual reserves.
  ///
  ///         Checks NOT performed for a user include:
  ///           - Validity / sanity of the recipient address.
  ///
  /// @param _tokenIn the address of the token being sold to the pool by the calling account.
  /// @param _tokenOut the address of the token being bought from the pool by the calling account.
  /// @param _poolType a number mapping to the PoolType enumeration (see ICronV1PoolEnums.sol::PoolType for the
  ///                  enumeration definition):
  ///                  Stable = 0
  ///                  Liquid = 1
  ///                  Volatile = 2
  ///                  Min. = 0, Max. = 2
  /// @param _amountIn the amount of the token being sold to the pool by the calling account.
  ///                  Min. > 0, Max. <= (2 ** 112) - 1
  /// @param _minTokenOut is the minimum amount of token out expected from the swap; if at least this amount is
  ///                     not provided, then the transaction reverts. This protects against sandwich
  ///                     and other attacks.
  /// @param _recipient an address to send the proceeds of token out from the swap.
  /// @return swapResult the result of the swap call.
  ///
  function swap(
    address _tokenIn,
    address _tokenOut,
    uint256 _poolType,
    uint256 _amountIn,
    uint256 _minTokenOut,
    address _recipient
  ) external returns (bytes memory swapResult);

  /// @notice Performs a join (mint) to the specified Cron-Fi Time-Weighted Average Market Maker (TWAMM) pool.
  ///         The amount of token A and B provided to the pool is given in liquidity A and B, respectively.
  ///         Specifiying the minimum nominal liquidity provided to the pool in min liquidity A and B for tokens
  ///         A and B, respectively, protects against attacks intended to capture user liquidity from price
  ///         manipulation.
  ///
  ///         Tokens A and B referred to herein are an abstraction atop Balancer Vaults notion of the tokens in
  ///         a two-token pool, tokens 0 and 1. Rather than have the user figure out the correct sort order of
  ///         the tokens and specify token 0 and related values correctly, the user need only specify values for
  ///         a given token address and this periphery relayer will correctly figure out the sort order and call
  ///         the vault low level functions appropriately, matching token A and B to token 0 and 1 as needed.
  ///
  ///         A recipient can be specified if the pool tokens (liquitity provider tokens) are to be directed
  ///         to an account different from the calling account, msg.sender.
  ///
  ///         IMPORTANT: Users must approve this contract on the Balancer Vault before any transactions can be used.
  ///                    This can be done by calling setRelayerApproval on the Balancer Vault contract and specifying
  ///                    this contract's address.
  ///
  ///         WARNING: The first time liquidity is provided to a Cron-Fi TWAMM pool, a minimum amount of
  ///                  liquidity is retained by the pool, with the corresponding pool tokens not provided to
  ///                  the calling account. (See miscellany/Constants.sol::MINIMUM_LIQUIDITY).
  ///
  ///         Checks performed on behalf of a user include:
  ///           - Specified pool exists.
  ///           - Pool has been funded and contains minimum liquidity amounts.
  ///           - Join liquidity amounts specified are greater than zero and available in the calling account
  ///             (msg.sender).
  ///           - The pro-rata liquidity providing algorithm collects at least both minimum specified liquidity
  ///             amounts to protect against price manipulation attacks.
  ///
  ///         Checks NOT performed for a user include:
  ///           - Validity / sanity of the recipient address.
  ///
  /// @param _tokenA the address of one pool asset.
  /// @param _tokenB the address of the other pool asset.
  /// @param _poolType a number mapping to the PoolType enumeration (see ICronV1PoolEnums.sol::PoolType for the
  ///                  enumeration definition):
  ///                  Stable = 0
  ///                  Liquid = 1
  ///                  Volatile = 2
  ///                  Min. = 0, Max. = 2
  /// @param _liquidityA the amount of tokenA to join the pool with.
  ///                    Min. > 0, Max. <= (2 ** 112) - 1
  /// @param _liquidityB the amount of tokenB to join the pool with.
  ///                    Min. > 0, Max. <= (2 ** 112) - 1
  /// @param _minLiquidityA the minimum amount of tokenA calculated pro-rata for joining the pool (protects against
  ///                       price manipulation, should be close to the amount specified for _liquidityA yet able to
  ///                       tolerate typical/expected price movements).
  ///                       Min. > 0, Max. <= _liquidityA
  /// @param _minLiquidityB the minimum amount of tokenB calculated pro-rata for joining the pool (protects against
  ///                       price manipulation, should be close to the amount specified for _liquidityB yet able to
  ///                       tolerate typical/expected price movements).
  ///                       Min. > 0, Max. <= _liquidityB
  /// @param _recipient is the address to send the pool tokens (liquidity provider tokens) to.
  /// @return joinResult the result of the join call.
  ///
  function join(
    address _tokenA,
    address _tokenB,
    uint256 _poolType,
    uint256 _liquidityA,
    uint256 _liquidityB,
    uint256 _minLiquidityA,
    uint256 _minLiquidityB,
    address _recipient
  ) external returns (bytes memory joinResult);

  /// @notice Performs an exit (burn) from the specified Cron-Fi Time-Weighted Average Market Maker (TWAMM) pool.
  ///         The amount of pool tokens (liquidity provider tokens) is specified by numLPTokens. Specifiying minimum
  ///         amounts of token A and B to receive from the pool in exchange for pool tokens can be done with min
  ///         amount out A and B, respectively. This protects against price manipulation and other attacks,
  ///         reverting if the minimums aren't received.
  ///
  ///         Tokens A and B referred to herein are an abstraction atop Balancer Vaults notion of the tokens in
  ///         a two-token pool, tokens 0 and 1. Rather than have the user figure out the correct sort order of
  ///         the tokens and specify token 0 and related values correctly, the user need only specify values for
  ///         a given token address and this periphery relayer will correctly figure out the sort order and call
  ///         the vault low level functions appropriately, matching token A and B to token 0 and 1 as needed.
  ///
  ///         A recipient can be specified if the tokens emitted are to be directed to an account different from the
  ///         calling account, msg.sender.
  ///
  ///         IMPORTANT: Users must approve this contract on the Balancer Vault before any transactions can be used.
  ///                    This can be done by calling setRelayerApproval on the Balancer Vault contract and specifying
  ///                    this contract's address.
  ///
  ///         Checks performed on behalf of a user include:
  ///           - Specified pool exists.
  ///           - Pool token amount specified is greater than zero and available in the calling account
  ///             (msg.sender).
  ///           - The specified minimum amounts of token A and B are received in the exchange for pool tokens or
  ///             the transaction reverts.
  ///
  ///         Checks NOT performed for a user include:
  ///           - Validity / sanity of the recipient address.
  ///
  /// @param _tokenA the address of pool asset tokenA
  /// @param _tokenB the address of pool asset tokenB
  /// @param _poolType a number mapping to the PoolType enumeration (see ICronV1PoolEnums.sol::PoolType for the
  ///                  enumeration definition):
  ///                  Stable = 0
  ///                  Liquid = 1
  ///                  Volatile = 2
  ///                  Min. = 0, Max. = 2
  /// @param _numLPTokens is the number of pool tokens (liquidity provider tokens) to redeem in exchange for tokens A
  ///                     and B from the pool.
  ///                     Min. > 0, Max. <= (2 ** 256) - 1
  /// @param _minAmountOutA is the minimum amount of tokenA to accept from the pool in exchange for pool tokens before
  ///                       reverting the transaction.
  ///                       Min. > 0, Max. <= (2 ** 112) - 1
  /// @param _minAmountOutB is the minimum amount of tokenB to accept from the pool in exchange for pool tokens before
  ///                       reverting the transaction.
  ///                       Min. > 0, Max. <= (2 ** 112) - 1
  /// @param _recipient is the address to send tokens A and B to from the exchanged pool tokens (liquidity provider
  ///                   tokens).
  /// @return exitResult the result of the exit call.
  ///
  function exit(
    address _tokenA,
    address _tokenB,
    uint256 _poolType,
    uint256 _numLPTokens,
    uint256 _minAmountOutA,
    uint256 _minAmountOutB,
    address _recipient
  ) external returns (bytes memory exitResult);

  /// @notice Gets a multicall array argument to perform a long-term (non-atomic) swap of the specified amount of token
  ///         in to token out on the Cron-Finance Time-Weighted Average Market Maker (TWAMM) pool uniquely identified
  ///         from the addreses of token in, token out, and the pool type.
  ///
  ///         The intervals specified is the duration over which to perform the long-term swap. An interval is a
  ///         number of blocks, depending on the pool type specified (See miscellany/Constants.sol::{STABLE_OBI,
  ///         LIQUID_OBI, VOLATILE_OBI}). The amount specified is divided by the number of blocks in the duration
  ///         of the trade, known as the sales rate. The sales rate is used to compute the swap when virtual orders are
  ///         executed (usually at block numbers divisible by the block interval, OBI, or at transactions against
  ///         the pool). Any excess amount not divisible by the trade duration is not taken for the trade (i.e. the
  ///         amount in specified is reduced to an amount wholely divisible by the trade duration).
  ///
  ///         A delegate address may be specified. The delegate address has the ability to withdraw or cancel the
  ///         long-term swap to the calling account's address at any time. The delegate cannot withdraw or cancel the
  ///         long-term swap to any address but the calling account's address. The delegate address cannot be modified
  ///         during the duration of the trade--the only mitigation is for the calling account to cancel the trade. If
  ///         the delegate is unspecified or the NULL address, the delegate is considered undefined and there is no such
  ///         role for the long-term swap.
  ///
  ///         IMPORTANT: Users must approve this contract on the Balancer Vault before any transactions can be used.
  ///                    This can be done by calling setRelayerApproval on the Balancer Vault contract and specifying
  ///                    this contract's address.
  ///
  ///         Checks performed on behalf of a user include:
  ///           - Pool specified by token in and out addresses and pool type exists.
  ///           - Pool has been funded and contains minimum liquidity amounts.
  ///           - Swap amount specified is greater than zero and available in the calling account (msg.sender).
  ///           - Intervals specified are greater than zero.
  ///           - Reducing the swap amount specified to the amount wholely divisible by the trade duration to
  ///             prevent losses due to fixed-precision limitations.
  ///
  ///         Checks NOT performed for a user include:
  ///           - Validity of the delegate address.
  ///
  /// @param _tokenIn the address of the token being sold to the pool by the calling account.
  /// @param _tokenOut the address of the token being bought from the pool by the calling account.
  /// @param _poolType a number mapping to the PoolType enumeration (see ICronV1PoolEnums.sol::PoolType for the
  ///                  enumeration definition):
  ///                  Stable = 0
  ///                  Liquid = 1
  ///                  Volatile = 2
  ///                  Min. = 0, Max. = 2
  /// @param _amountIn the amount of the token being sold to the pool by the calling account.
  ///                  Min. > 0, Max. <= (2 ** 112) - 1
  /// @param _intervals is the number of intervals to execute the long-term swap before expiring. An interval can be 75
  ///                   blocks (Stable Pool), 300 blocks (Liquid Pool) or 1200 blocks (Volatile Pool).
  ///                   Min. = 0, Max. = miscellany/Constants.sol::STABLE_MAX_INTERVALS,
  ///                                    miscellany/Constants.sol::LIQUID_MAX_INTERVALS,
  ///                                    miscellany/Constants.sol::VOLATILE_MAX_INTERVALS
  ///                                    (depending on POOL_TYPE).
  /// @param _delegate is an account that is able to withdraw or cancel the long-term swap on behalf of the
  ///                  calling account, as long as the recipient specified for withdraw or cancellation is the
  ///                  original calling account.
  ///                  If the delegate is set to the calling account, then the delegate is set
  ///                  to the null address (i.e. no delegate role granted).
  ///
  /// @return longTermSwapResult the result of the long term swap call.
  /// @return orderId of the long term order if the long term order was successfully issued.
  ///
  function longTermSwap(
    address _tokenIn,
    address _tokenOut,
    uint256 _poolType,
    uint256 _amountIn,
    uint256 _intervals,
    address _delegate
  ) external returns (bytes memory longTermSwapResult, uint256 orderId);

  /// @notice Performs a withdrawal of a long-term (non-atomic) swap, given the order id of the swap.
  ///
  ///         Multiple withdrawals are possible througout the duration of a long-term swap, with a final withdrawal
  ///         possible after the swap has expired.
  ///
  ///         If a delegate has been specified in the long-term swap and is performing the withdrawal, the _recipient
  ///         address must be the original long-term swap owner (calling account, msg.sender) or the withdrawal will
  ///         revert.
  ///
  ///         If the owner (calling account, msg.sender) is performing the withdrawal, the funds may be directed to
  ///         another account, the address of which is specified in the recipient parameter.
  ///
  ///         IMPORTANT: Users must approve this contract on the Balancer Vault before any transactions can be used.
  ///                    This can be done by calling setRelayerApproval on the Balancer Vault contract and specifying
  ///                    this contract's address.
  ///
  ///         Tokens A and B referred to herein are an abstraction atop Balancer Vaults notion of the tokens in
  ///         a two-token pool, tokens 0 and 1. Rather than have the user figure out the correct sort order of
  ///         the tokens and specify token 0 and related values correctly, the user need only specify values for
  ///         a given token address and this periphery relayer will correctly figure out the sort order and call
  ///         the vault low level functions appropriately, matching token A and B to token 0 and 1 as needed. Since
  ///         this method need not specify any amounts of either asset token, the two assets are only used to correctly
  ///         identify the pool, given the pool type.
  ///
  ///         Checks performed on behalf of a user include:
  ///           - Specified pool exists.
  ///
  ///         Checks NOT performed for a user include:
  ///           - Validity / sanity of the recipient address.
  ///
  /// @param _tokenA the address of pool asset token A
  /// @param _tokenB the address of pool asset token B
  /// @param _poolType a number mapping to the PoolType enumeration (see ICronV1PoolEnums.sol::PoolType for the
  ///                  enumeration definition):
  ///                  Stable = 0
  ///                  Liquid = 1
  ///                  Volatile = 2
  ///                  Min. = 0, Max. = 2
  /// @param _orderId is the id of the long-term swap order being withdrawn.
  ///                 Min. = 0, Max. = (2 ** 256) - 1
  /// @param _recipient is the address of the order owner (original order calling account, msg.sender) if this withdraw
  ///                   transaction is performed by a delegate. The call will revert if an address other than the order
  ///                   owner is specified. If the withdraw transaction is performed by the order owner, then the
  ///                   recipient can be specified as any account address.
  /// @return withdrawResult the result of the withdraw call.
  ///
  function withdraw(
    address _tokenA,
    address _tokenB,
    uint256 _poolType,
    uint256 _orderId,
    address _recipient
  ) external returns (bytes memory withdrawResult);

  /// @notice Performs a cancel of a long-term (non-atomic) swap, given the order id of the swap.
  ///
  ///         Cancellation is possible up until the swap order expiry. Already executed portions of the long-term
  ///         swap are remitted along with any remaining unsold tokens.
  ///
  ///         If a delegate has been specified in the long-term swap and is performing the cancellation, the _recipient
  ///         address must be the original long-term swap owner (calling account, msg.sender) or the cancellation will
  ///         revert.
  ///
  ///         If the owner (calling account, msg.sender) is performing the cancellation, the funds may be directed to
  ///         another account, the address of which is specified in the recipient parameter.
  ///
  ///         IMPORTANT: Users must approve this contract on the Balancer Vault before any transactions can be used.
  ///                    This can be done by calling setRelayerApproval on the Balancer Vault contract and specifying
  ///                    this contract's address.
  ///
  ///         Tokens A and B referred to herein are an abstraction atop Balancer Vaults notion of the tokens in
  ///         a two-token pool, tokens 0 and 1. Rather than have the user figure out the correct sort order of
  ///         the tokens and specify token 0 and related values correctly, the user need only specify values for
  ///         a given token address and this periphery relayer will correctly figure out the sort order and call
  ///         the vault low level functions appropriately, matching token A and B to token 0 and 1 as needed. Since
  ///         this method need not specify any amounts of either asset token, the two assets are only used to correctly
  ///         identify the pool, given the pool type.
  ///
  ///         Checks performed on behalf of a user include:
  ///           - Specified pool exists.
  ///
  ///         Checks NOT performed for a user include:
  ///           - Validity / sanity of the recipient address.
  ///
  /// @param _tokenA the address of pool asset token A
  /// @param _tokenB the address of pool asset token B
  /// @param _poolType a number mapping to the PoolType enumeration (see ICronV1PoolEnums.sol::PoolType for the
  ///                  enumeration definition):
  ///                  Stable = 0
  ///                  Liquid = 1
  ///                  Volatile = 2
  ///                  Min. = 0, Max. = 2
  /// @param _orderId is the id of the long-term swap order being withdrawn.
  ///                 Min. = 0, Max. = (2 ** 256) - 1
  /// @param _recipient is the address of the order owner (original order calling account, msg.sender) if this cancel
  ///                   transaction is performed by a delegate. The call will revert if an address other than the order
  ///                   owner is specified. If the cancel transaction is performed by the order owner, then the
  ///                   recipient can be specified as any account address.
  /// @return cancelResult the result of the cancel call.
  ///
  function cancel(
    address _tokenA,
    address _tokenB,
    uint256 _poolType,
    uint256 _orderId,
    address _recipient
  ) external returns (bytes memory cancelResult);

  /// @notice Gets the Cron-Fi pool address, given the pool's asset token addresses and pool type. This method is
  ///         useful for inspecting the pool that methods in this periphery relayer will be operating on by getting the
  ///         target pool address from the provided parameters.
  ///
  ///         Tokens A and B referred to herein are an abstraction atop Balancer Vaults notion of the tokens in
  ///         a two-token pool, tokens 0 and 1. Rather than have the user figure out the correct sort order of
  ///         the tokens and specify token 0 and related values correctly, the user need only specify values for
  ///         a given token address and this periphery relayer will correctly figure out the sort order and call
  ///         the vault low level functions appropriately, matching token A and B to token 0 and 1 as needed. Since
  ///         this method need not specify any amounts of either asset token, the two assets are only used to correctly
  ///         identify the pool, given the pool type.
  ///
  /// @param _tokenA the address of pool asset token A
  /// @param _tokenB the address of pool asset token B
  /// @param _poolType a number mapping to the PoolType enumeration (see ICronV1PoolEnums.sol::PoolType for the
  ///                  enumeration definition):
  ///                  Stable = 0
  ///                  Liquid = 1
  ///                  Volatile = 2
  ///                  Min. = 0, Max. = 2
  /// @return pool the address of the unique Cron-Fi pool for the provided token addresses and pool type. If
  ///              the value returned is the NULL address (0), there is not Cron-Fi pool matching the provided
  ///              function parameters.
  ///
  function getPoolAddress(
    address _tokenA,
    address _tokenB,
    uint256 _poolType
  ) external view returns (address pool);

  /// @notice A convenience for getting the order data for a given order id in a pool specified by the provided token
  ///         addresses and pool type.
  ///
  ///         If the pool cannot be identified or does not exist given the provided parameters, the call
  ///         reverts with a non-existing pool error code.
  ///
  ///         Tokens A and B referred to herein are an abstraction atop Balancer Vaults notion of the tokens in
  ///         a two-token pool, tokens 0 and 1. Rather than have the user figure out the correct sort order of
  ///         the tokens and specify token 0 and related values correctly, the user need only specify values for
  ///         a given token address and this periphery relayer will correctly figure out the sort order and call
  ///         the vault low level functions appropriately, matching token A and B to token 0 and 1 as needed. Since
  ///         this method need not specify any amounts of either asset token, the two assets are only used to correctly
  ///         identify the pool, given the pool type.
  ///
  ///         NOTE: It is more gas efficient to call the method of the same name on the target Cron-Fi pool contract.
  ///               This method is provided as a convenience for users of web interfaces like Etherscan or Gnosis Safe.
  ///
  /// @param _tokenA the address of pool asset token A
  /// @param _tokenB the address of pool asset token B
  /// @param _poolType a number mapping to the PoolType enumeration (see ICronV1PoolEnums.sol::PoolType for the
  ///                  enumeration definition):
  ///                  Stable = 0
  ///                  Liquid = 1
  ///                  Volatile = 2
  ///                  Min. = 0, Max. = 2
  /// @return pool the address of the unique Cron-Fi pool for the provided token addresses and pool type. If
  ///              the value returned is the NULL address (0), there is not Cron-Fi pool matching the provided
  ///              function parameters.
  /// @return order is the data for the specified order id. See ICronV1PoolEnums.sol for details on the Order
  ///               struct. If there the order id specified is invalid or expired and withdrawn, then the order
  ///               struct fields will be zero.
  ///
  function getOrder(
    address _tokenA,
    address _tokenB,
    uint256 _poolType,
    uint256 _orderId
  ) external view returns (address pool, Order memory order);

  /// @notice Gets the library address that this periphery relayer delegate calls
  ///         to perform Cron-Fi pool operations on behalf of the calling account.
  /// @return the address of this periphery relayer's library of functions that
  ///         operate directly on the Balancer Vault.
  ///
  function getLibrary() external view returns (address);

  /// @notice Gets the Balancer Vault that this periphery relayer is serving.
  /// @return a Balancer Vault instance.
  ///
  function getVault() external view returns (IVault);
}