pragma solidity ^0.5.0;
// File: Modifier from : @openzeppelin/contracts/access/roles/MinterRole.sol

import "../openzeppelin/Roles.sol";

contract Frozen {
  using Roles for Roles.Role;

  event AccountFrozen(address indexed account);
  event AccountUnfrozen(address indexed account);

  Roles.Role private _frozen;

  modifier checkFrozen(address from) {
    require(!isFrozen(from), "Frozen: Sender's tranfers are frozen");
    _;
  }

  function isFrozen(address account) public view returns (bool) {
    return _frozen.has(account);
  }

  function _freezeAccount(address account) internal {
    _frozen.add(account);
    emit AccountFrozen(account);
  }

  function _unfreezeAccount(address account) internal {
    _frozen.remove(account);
    emit AccountUnfrozen(account);
  }
}