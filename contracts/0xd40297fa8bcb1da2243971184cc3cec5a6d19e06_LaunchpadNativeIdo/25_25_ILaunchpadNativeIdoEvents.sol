// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import '../IdoStorage/IIdoStorageState.sol';


interface ILaunchpadNativeIdoEvents {
  /**
   * Event for token purchase logging.
   * @param purchaser  who paid for the tokens.
   * @param referral  referral used in the purchase.
   * @param investment  native coins paid for the purchase.
   * @param vesting  vesting of the investment.
   * @param tokensSold  amount of tokens purchased.
   * @param round  round of the purchase
   */
  event TokensPurchased(
    address indexed purchaser,
    address indexed referral,
    uint256 investment,
    IIdoStorageState.Vesting indexed vesting,
    uint256 tokensSold,
    uint256 round
  );

  /**
   * Event for pause state update.
   * @param paused  new paused value.
   */
  event PausedUpdated(bool paused);

  /**
   * Event for price feed update time threshold state update.
   * @param priceFeedTimeThreshold  new price feed time threshold value.
   */
  event PriceFeedTimeThresholdUpdated(uint256 priceFeedTimeThreshold);

  event ERC20Recovered(address token, uint256 amount);
  event NativeRecovered(uint256 amount);
}