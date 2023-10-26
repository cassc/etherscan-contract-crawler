// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import '../IdoStorage/IIdoStorageState.sol';


interface ILaunchpadErc20IdoActions {
  /**
   * @dev Method allows to purchase the tokens.
   * @param collateral_  collateral token.
   * @param investment_  collateral token investment.
   * @param vesting_  vesting of the investment.
   * @param referral_  referral owner.
   */
  function buyTokens(address collateral_, uint256 investment_, IIdoStorageState.Vesting vesting_, address referral_) external;

  /**
   * @dev Method allows to purchase the tokens.
   * @param collateral_  collateral token.
   * @param investment_  collateral token investment.
   * @param vesting_  vesting of the investment.
   * @param beneficiary_  address performing the token purchase.
   * @param referral_  referral owner.
   */
  function buyTokensFor(
    address collateral_,
    uint256 investment_,
    IIdoStorageState.Vesting vesting_,
    address beneficiary_,
    address referral_
  ) external;

  /**
   * @dev Allows to recover ERC20 from contract.
   * @param token_  ERC20 token address.
   * @param amount_  ERC20 token amount.
   */
  function recoverERC20(address token_, uint256 amount_) external;

  /**
   * @return True if token is collateral.
   * @param collateral_  addresses of the collateral token.
   */
  function isCollateral(address collateral_) external view returns (bool);

  /**
   * @return Address where funds are collected.
   */
  function getWallet() external view returns (address);

  /**
   * @return Address of the ido storage.
   */
  function getIdoStorage() external view returns (address);

  /**
   * @return Amount of collateral tokens raised.
   * @param collateral_  addresses of the collateral token.
   */
  function getRaised(address collateral_) external view returns (uint256);
}