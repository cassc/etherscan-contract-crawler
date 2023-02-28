// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
@title RecoverableUpgradeable
@author Leo
@notice Recovers stuck BNB and ERC20 tokens
@dev You can inhertit from this contract to support recovering stuck BNB and ERC20 tokens
*/
contract RecoverableUpgradeable is AccessControlUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /**
   * @notice Recovers stuck BNB in the contract
   * @param _amount Amount to recover
   */
  function recoverBNB(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(address(this).balance >= _amount, "RecoverableUpgradeable::recoverBNB: invalid input amount");
    (bool success, ) = payable(msg.sender).call{ value: _amount }("");
    require(success, "recover failed");

    emit BNBRecovered(_amount);
  }

  /**
   * @notice Recovers stuck ERC20 token in the contract
   * @param _token An ERC20 token address
   * @param _amount Amount to recover
   */
  function recoverERC20(IERC20Upgradeable _token, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_token.balanceOf(address(this)) >= _amount, "RecoverableUpgradeable::recoverERC20: invalid input amount");

    _token.safeTransfer(msg.sender, _amount);

    emit ERC20Recovered(_token, _amount);
  }

  event BNBRecovered(uint256 amount);
  event ERC20Recovered(IERC20Upgradeable indexed token, uint256 amount);
}