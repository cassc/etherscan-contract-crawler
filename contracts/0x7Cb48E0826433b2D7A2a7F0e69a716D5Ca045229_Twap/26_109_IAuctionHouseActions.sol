// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

/// @title Open Auction House actions
/// @notice Contains all actions that can be called by anyone
interface IAuctionHouseActions {
  /**
   * @notice Starts an auction
   * @dev This will:
   * - update the oracles
   * - calculate the target price
   * - check stabilisation case
   * - create allowance.
   * - Set start / end prices of the auction
   */
  function start() external returns (uint64 newRound);

  /**
   * @notice Buy for an amount of <WETH, BANK> for as much FLOAT tokens as possible.
   * @dev Expansion, Protocol sells FLOAT for pair.
    As the price descends there should be no opportunity for slippage causing failure
    `msg.sender` should already have given the auction allowance for at least `wethIn` and `bankIn`.
   * `wethInMax` / `bankInMax` < 2**256 / 10**18, assumption is that totalSupply
   * doesn't exceed type(uint128).max
   * @param wethInMax The max amount of WETH to send (takes maximum from given ratio).
   * @param bankInMax The max amount of BANK to send (takes maximum from given ratio).
   * @param floatOutMin The minimum amount of FLOAT that must be received for this transaction not to revert.
   * @param to Recipient of the FLOAT.
   * @param deadline Unix timestamp after which the transaction will revert.
   */
  function buy(
    uint256 wethInMax,
    uint256 bankInMax,
    uint256 floatOutMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 usedWethIn,
      uint256 usedBankIn,
      uint256 usedFloatOut
    );

  /**
   * @notice Sell an amount of FLOAT for the given reward tokens.
   * @dev Contraction, Protocol buys FLOAT for pair. `msg.sender` should already have given the auction allowance for at least `floatIn`.
   * @param floatIn The amount of FLOAT to sell.
   * @param wethOutMin The minimum amount of WETH that can be received before the transaction reverts.
   * @param bankOutMin The minimum amount of BANK that can be received before the tranasction reverts.
   * @param to Recipient of <WETH, BANK>.
   * @param deadline Unix timestamp after which the transaction will revert.
   */
  function sell(
    uint256 floatIn,
    uint256 wethOutMin,
    uint256 bankOutMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 usedfloatIn,
      uint256 usedWethOut,
      uint256 usedBankOut
    );
}