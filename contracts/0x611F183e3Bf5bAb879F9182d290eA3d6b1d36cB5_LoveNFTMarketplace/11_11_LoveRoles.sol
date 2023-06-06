// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import '@openzeppelin/contracts/access/Ownable.sol';

contract LoveRoles is Ownable {
  mapping(address => mapping(string => bool)) private users;

  event RoleGranted(address indexed account, string role);
  event RoleRevoked(address indexed account, string role);

  modifier hasRole(string memory role) {
    require(users[msg.sender][role] || msg.sender == owner(), 'account doesnt have this role');
    _;
  }

  function grantRole(address account, string calldata role) external onlyOwner {
    require(!users[account][role], 'role already granted');
    users[account][role] = true;

    emit RoleGranted(account, role);
  }

  function revokeRole(address account, string calldata role) external onlyOwner {
    require(users[account][role], 'role already revoked');
    users[account][role] = false;

    emit RoleRevoked(account, role);
  }

  function checkRole(address accountToCheck, string calldata role) external view returns (bool) {
    return users[accountToCheck][role];
  }
}