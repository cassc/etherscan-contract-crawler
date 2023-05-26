// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/AccessControl.sol';

contract ElyfiAccessControl is AccessControl {
  bytes32 public constant SNAPSHOT_MAKER_ROLE = keccak256('SNAPSHOT_MAKER');

  modifier onlySnapshotMaker() {
    require(_isSnapshotMaker(msg.sender), 'Restricted to snapshot maker.');
    _;
  }

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Restricted to admin.");
    _;
  }

  function isSnapshotMaker(address account) external view returns (bool) {
    return _isSnapshotMaker(account);
  }

  function _isSnapshotMaker(address account) internal view returns (bool) {
    return hasRole(SNAPSHOT_MAKER_ROLE, account);
  }
}