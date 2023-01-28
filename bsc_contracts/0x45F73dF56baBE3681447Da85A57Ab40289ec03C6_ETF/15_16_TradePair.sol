pragma solidity ^0.5.0;
// File: Modifier from : @openzeppelin/contracts/access/roles/MinterRole.sol

import "../openzeppelin/Roles.sol";

contract TradePair {
  using Roles for Roles.Role;

  event PairAdded(address indexed account);
  event PairRemoved(address indexed account);

  Roles.Role private _pairs;

  modifier checkWhitelist(address account) {
    require(isTradePair(account), "Trade pair: Address is not trade pair");
    _;
  }

  function isTradePair(address account) public view returns (bool) {
    return _pairs.has(account);
  }

  function _addPair(address account) internal {
    _pairs.add(account);
    emit PairAdded(account);
  }

  function _removePair(address account) internal {
    _pairs.remove(account);
    emit PairRemoved(account);
  }
}