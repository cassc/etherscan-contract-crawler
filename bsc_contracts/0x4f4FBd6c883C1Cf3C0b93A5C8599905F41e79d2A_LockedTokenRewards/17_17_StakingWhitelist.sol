pragma solidity ^0.5.0;
// File: Modifier from : @openzeppelin/contracts/access/roles/MinterRole.sol

import "../openzeppelin/Roles.sol";

contract StakingWhitelistable {
  using Roles for Roles.Role;

  event AddressWhitelisted(address indexed account);
  event AddressDelisted(address indexed account);

  Roles.Role private _whitelist;

  modifier checkWhitelist(address account) {
    require(isWhitelisted(account), "Whitelistable: Account is not whitelisted");
    _;
  }

  function isWhitelisted(address account) public view returns (bool) {
    return _whitelist.has(account);
  }

  function _whitelistAccount(address account) internal {
    _whitelist.add(account);
    emit AddressWhitelisted(account);
  }

  function _delistAccount(address account) internal {
    _whitelist.remove(account);
    emit AddressDelisted(account);
  }
}