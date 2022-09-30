// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@mean-finance/dca-v2-core/contracts/interfaces/IDCAHub.sol';

interface ILegacyDCAHub {
  /// @notice Information about a swap
  struct SwapInfo {
    // The tokens involved in the swap
    TokenInSwap[] tokens;
    // The pairs involved in the swap
    PairInSwap[] pairs;
  }

  /// @notice Information about a token's role in a swap
  struct TokenInSwap {
    // The token's address
    address token;
    // How much will be given of this token as a reward
    uint256 reward;
    // How much of this token needs to be provided by swapper
    uint256 toProvide;
    // How much of this token will be paid to the platform
    uint256 platformFee;
  }

  /// @notice Information about a pair in a swap
  struct PairInSwap {
    // The address of one of the tokens
    address tokenA;
    // The address of the other token
    address tokenB;
    // How much is 1 unit of token A when converted to B
    uint256 ratioAToB;
    // How much is 1 unit of token B when converted to A
    uint256 ratioBToA;
    // The swap intervals involved in the swap, represented as a byte
    bytes1 intervalsInSwap;
  }

  /**
   * @notice Returns all information related to the next swap
   * @dev Will revert with:
   *      - With InvalidTokens if tokens are not sorted, or if there are duplicates
   *      - With InvalidPairs if pairs are not sorted (first by indexTokenA and then indexTokenB), or if indexTokenA >= indexTokenB for any pair
   * @param tokens The tokens involved in the next swap
   * @param pairs The pairs that you want to swap. Each element of the list points to the index of the token in the tokens array
   * @return swapInformation The information about the next swap
   */
  function getNextSwapInfo(address[] calldata tokens, IDCAHub.PairIndexes[] calldata pairs)
    external
    view
    returns (SwapInfo memory swapInformation);

  /**
   * @notice Executes a flash swap
   * @dev Will revert with:
   *      - With InvalidTokens if tokens are not sorted, or if there are duplicates
   *      - With InvalidPairs if pairs are not sorted (first by indexTokenA and then indexTokenB), or if indexTokenA >= indexTokenB for any pair
   *      - With Paused if swaps are paused by protocol
   *      - With NoSwapsToExecute if there are no swaps to execute for the given pairs
   *      - With LiquidityNotReturned if the required tokens were not back during the callback
   * @param tokens The tokens involved in the next swap
   * @param pairsToSwap The pairs that you want to swap. Each element of the list points to the index of the token in the tokens array
   * @param rewardRecipient The address to send the reward to
   * @param callbackHandler Address to call for callback (and send the borrowed tokens to)
   * @param borrow How much to borrow of each of the tokens in tokens. The amount must match the position of the token in the tokens array
   * @param callbackData Bytes to send to the caller during the callback
   * @return Information about the executed swap
   */
  function swap(
    address[] calldata tokens,
    IDCAHub.PairIndexes[] calldata pairsToSwap,
    address rewardRecipient,
    address callbackHandler,
    uint256[] calldata borrow,
    bytes calldata callbackData
  ) external returns (SwapInfo memory);
}