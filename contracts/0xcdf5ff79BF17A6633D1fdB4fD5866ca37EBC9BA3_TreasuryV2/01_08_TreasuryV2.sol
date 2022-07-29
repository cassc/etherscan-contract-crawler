// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable as Ownable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TreasuryV2 is Initializable, Ownable {
  using SafeERC20 for IERC20;

  function initialize() public initializer {
    __Ownable_init();
  }

  receive() external payable {}

  fallback() external payable {}

  /**
   * @notice Transfer target token to recipient.
   * @param token Target token.
   * @param recipient Recipient.
   * @param amount Transfer amount.
   */
  function transfer(
    address token,
    address recipient,
    uint256 amount
  ) external onlyOwner returns (bool) {
    require(amount > 0, "Treasury::transfer: negative or zero amount");
    require(recipient != address(0), "Treasury::transfer: invalid recipient");
    IERC20(token).safeTransfer(recipient, amount);
    return true;
  }

  /**
   * @notice Transfer ETH to recipient.
   * @param recipient Recipient.
   * @param amount Transfer amount.
   */
  function transferETH(address payable recipient, uint256 amount) external onlyOwner returns (bool) {
    require(amount > 0, "Treasury::transferETH: negative or zero amount");
    require(recipient != address(0), "Treasury::transferETH: invalid recipient");
    recipient.transfer(amount);
    return true;
  }

  /**
   * @notice Approve target token to recipient.
   * @param token Target token.
   * @param recipient Recipient.
   * @param amount Approve amount.
   */
  function approve(
    address token,
    address recipient,
    uint256 amount
  ) external onlyOwner returns (bool) {
    uint256 allowance = IERC20(token).allowance(address(this), recipient);
    if (allowance > 0) {
      IERC20(token).safeApprove(recipient, 0);
    }
    IERC20(token).safeApprove(recipient, amount);
    return true;
  }
}