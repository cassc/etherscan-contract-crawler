// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@mean-finance/dca-v2-core/contracts/interfaces/IDCAHub.sol';
import '@mean-finance/dca-v2-core/contracts/interfaces/IDCAHubSwapCallee.sol';
import '@mean-finance/swappers/solidity/interfaces/ISwapAdapter.sol';
import '@mean-finance/swappers/solidity/contracts/extensions/Shared.sol';
import './ILegacyDCAHub.sol';

interface IDCAHubSwapper is IDCAHubSwapCallee {
  /// @notice Parameters to execute a swap with dexes
  struct SwapWithDexesParams {
    // The address of the DCAHub
    IDCAHub hub;
    // The tokens involved in the swap
    address[] tokens;
    // The pairs to swap
    IDCAHub.PairIndexes[] pairsToSwap;
    // Bytes to send to the oracle when executing a quote
    bytes oracleData;
    // The accounts that should be approved for spending
    Allowance[] allowanceTargets;
    // The different swappers involved in the swap
    address[] swappers;
    // The different swaps to execute
    SwapExecution[] executions;
    // Address that will receive all unspent tokens
    address leftoverRecipient;
    // A list of tokens to check for unspent balance. These should be tokens that were
    // not `toProvide` nor `reward` tokens
    address[] intermediateTokensToCheck;
    // Deadline when the swap becomes invalid
    uint256 deadline;
  }

  /// @notice The data necessary for a swap to be executed
  struct SwapExecution {
    // The index of the swapper in the swapper array
    uint8 swapperIndex;
    // The swap's execution
    bytes swapData;
  }

  /// @notice Parameters to execute an optimized swap
  struct OptimizedSwapParams {
    // The address of the DCAHub
    IDCAHub hub;
    // The tokens involved in the swap
    address[] tokens;
    // The pairs to swap
    IDCAHub.PairIndexes[] pairsToSwap;
    // Bytes to send to the oracle when executing a quote
    bytes oracleData;
    // The accounts that should be approved for spending
    Allowance[] allowanceTargets;
    // The data for the callback, already encoded
    bytes callbackData;
    // Deadline when the swap becomes invalid
    uint256 deadline;
  }

  /// @notice Parameters to execute a swap for caller
  struct SwapForCallerParams {
    // The address of the DCAHub
    IDCAHub hub;
    // The tokens involved in the swap
    address[] tokens;
    // The pairs to swap
    IDCAHub.PairIndexes[] pairsToSwap;
    // Bytes to send to the oracle when executing a quote
    bytes oracleData;
    // The minimum amount of tokens to receive as part of the swap
    uint256[] minimumOutput;
    // The maximum amount of tokens to provide as part of the swap
    uint256[] maximumInput;
    // Address that will receive all the tokens from the swap
    address recipient;
    // Deadline when the swap becomes invalid
    uint256 deadline;
  }

  /// @notice Thrown when the reward is less that the specified minimum
  error RewardNotEnough();

  /// @notice Thrown when the amount to provide is more than the specified maximum
  error ToProvideIsTooMuch();

  /// @notice Thrown when the callback is executed with an unexpected swap plan
  error UnexpectedSwapPlan();

  /**
   * @notice Executes a swap for the caller, by sending them the reward, and taking from them the needed tokens
   * @dev Can only be called by user with appropriate role
   *      Will revert:
   *      - With RewardNotEnough if the minimum output is not met
   *      - With ToProvideIsTooMuch if the hub swap requires more than the given maximum input
   * @return The information about the executed swap
   */
  function swapForCaller(SwapForCallerParams calldata parameters) external payable returns (IDCAHub.SwapInfo memory);

  /**
   * @notice Executes a swap with the given swappers, and sends all unspent tokens to the given recipient
   * @dev Can only be called by user with appropriate role
   * @return The information about the executed swap
   */
  function swapWithDexes(SwapWithDexesParams calldata parameters) external payable returns (IDCAHub.SwapInfo memory);

  /**
   * @notice Meant to be used by Mean Finance keepers, as an cheaper way to execute swaps. This function executes a
   *         swap with the given swappers, but sends some of the unspent tokens back to the hub. This means that they
   *         will be considered part of the protocol's balance. Unspent tokens that were given as reward will be
   *         sent to the provided recipient
   * @dev Can only be called by user with appropriate role
   * @return The information about the executed swap
   */
  function swapWithDexesForMean(SwapWithDexesParams calldata parameters) external payable returns (IDCAHub.SwapInfo memory);

  /**
   * @notice Executes an optimized swap, by providing parameters already encoded
   * @dev Can only be called by user with appropriate role
   * @return The information about the executed swap
   */
  function optimizedSwap(OptimizedSwapParams calldata parameters) external payable returns (IDCAHub.SwapInfo memory);

  /**
   * @notice Revokes ERC20 allowances for the given spenders
   * @dev Can only be called an admin
   * @param revokeActions The spenders and tokens to revoke
   */
  function revokeAllowances(ISwapAdapter.RevokeAction[] calldata revokeActions) external;

  /**
   * @notice Sends the given token to the recipient
   * @dev Can only be called an admin
   * @param token The token to send to the recipient (can be an ERC20 or the protocol token)
   * @param amount The amount to transfer to the recipient
   * @param recipient The address of the recipient
   */
  function sendDust(
    address token,
    uint256 amount,
    address recipient
  ) external;
}