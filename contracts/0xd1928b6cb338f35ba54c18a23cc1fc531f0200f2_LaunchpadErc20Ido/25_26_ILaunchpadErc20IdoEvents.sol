// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import '../IdoStorage/IIdoStorageState.sol';


interface ILaunchpadErc20IdoEvents {
  /**
   * Event for token purchase logging.
   * @param purchaser  who paid for the tokens.
   * @param collateral  collateral token used in the purchase.
   * @param referral  referral used in the purchase.
   * @param investment  collateral tokens paid for the purchase.
   * @param vesting  vesting of the investment.
   * @param tokensSold  amount of tokens purchased.
   * @param round  round of the purchase
   */
  event TokensPurchased(
    address indexed purchaser,
    address indexed collateral,
    address indexed referral,
    uint256 investment,
    IIdoStorageState.Vesting vesting,
    uint256 tokensSold,
    uint256 round
  );

  /**
   * Event for pause state update.
   * @param paused  new paused value.
   */
  event PausedUpdated(bool paused);

  event ERC20Recovered(address token, uint256 amount);
  event NativeRecovered(uint256 amount);
}