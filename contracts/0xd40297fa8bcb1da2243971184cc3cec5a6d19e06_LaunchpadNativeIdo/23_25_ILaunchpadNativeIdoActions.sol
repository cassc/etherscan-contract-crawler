// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import '../IdoStorage/IIdoStorageState.sol';


interface ILaunchpadNativeIdoActions {
  /**
   * @dev Method allows to purchase the tokens.
   * @param vesting_  vesting of the investment.
   * @param referral_  referral owner.
   */
  function buyTokens(IIdoStorageState.Vesting vesting_, address referral_) external payable;

  /**
   * @dev Method allows to purchase the tokens.
   * @param vesting_  vesting of the investment.
   * @param beneficiary_  address performing the token purchase.
   * @param referral_  referral owner.
   */
  function buyTokensFor(IIdoStorageState.Vesting vesting_, address beneficiary_, address referral_) external payable;

  /**
   * @dev Sets price feed update time threshold state.
   * @param priceFeedTimeThreshold_  new value.
   */
  function setPriceFeedTimeThreshold(uint256 priceFeedTimeThreshold_) external;

  /**
   * @dev Allows to recover native coin from contract.
   */
  function recoverNative() external;

  /**
   * @dev Allows to recover ERC20 from contract.
   * @param token_  ERC20 token address.
   * @param amount_  ERC20 token amount.
   */
  function recoverERC20(address token_, uint256 amount_) external;

  /**
   * @return Address where funds are collected.
   */
  function getWallet() external view returns (address);

  /**
   * @return Address of the ido storage.
   */
  function getIdoStorage() external view returns (address);

  /**
   * @return Amount of funds raised.
   */
  function getRaised() external view returns (uint256);

  /**
   * @return Price feed update time threshold.
   */
  function getPriceFeedTimeThreshold() external view returns (uint256);
}