// SPDX-License-Identifier: PROPRIETARY

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Authorized is Ownable {
  mapping(uint8 => mapping(address => bool)) public permissions;

  constructor() {}

  // 0 - Admin
  // 1 - Controller
  // 2 - Operator
  // 3 - Executer
  modifier isAuthorized(uint8 index) {
    if (!permissions[index][_msgSender()]) {
      revert("Account does not have permission");
    }
    _;
  }

  function getAllPermissions(address wallet) external view returns (bool[] memory results) {
    results = new bool[](4);
    for (uint8 i = 0; i < 4; i++) results[i] = permissions[i][wallet];
  }

  function safeApprove(
    address token,
    address spender,
    uint amount
  ) external isAuthorized(0) {
    IERC20(token).approve(spender, amount);
  }

  function safeTransfer(
    address token,
    address receiver,
    uint amount
  ) external isAuthorized(0) {
    IERC20(token).transfer(receiver, amount);
  }

  function safeWithdraw() external isAuthorized(0) {
    payable(_msgSender()).transfer(address(this).balance);
  }

  function grantPermission(address operator, uint8[] memory grantedPermissions) external isAuthorized(0) {
    for (uint8 i = 0; i < grantedPermissions.length; i++) permissions[grantedPermissions[i]][operator] = true;
  }

  function revokePermission(address operator, uint8[] memory revokedPermissions) external isAuthorized(0) {
    for (uint8 i = 0; i < revokedPermissions.length; i++) permissions[revokedPermissions[i]][operator] = false;
  }
}