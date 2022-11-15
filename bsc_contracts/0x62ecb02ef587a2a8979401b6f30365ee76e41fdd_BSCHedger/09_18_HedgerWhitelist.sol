// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import { Ownable } from 'openzeppelin-contracts/access/Ownable.sol';
import { EnumerableSet } from 'openzeppelin-contracts/utils/structs/EnumerableSet.sol';

// import { IHedgerWhitelist } from './interfaces/IHedgerWhitelist.sol';

contract HedgerWhitelist is Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;

  EnumerableSet.AddressSet private whitelist;
  
  bool public isFrozen = false;

  modifier notFrozen() {
    require(!isFrozen, 'Whitelist frozen');
    _;
  }

  function approved(address addr) public view notFrozen returns (bool) {
    require(whitelist.contains(addr), 'Address not whitelisted');
    return true;
  }

  function add(address addr) public onlyOwner {
    whitelist.add(addr);
  }

  function addBulk(address[] memory addrs) public onlyOwner {
    for (uint i = 0; i < addrs.length;) {
      whitelist.add(addrs[i]);
      unchecked {
        i++;
      }
    }
  }

  function remove(address addr) public onlyOwner {
    whitelist.remove(addr);
  }

  function removeBulk(address[] memory addrs) public onlyOwner {
    for (uint i = 0; i < addrs.length;) {
      whitelist.remove(addrs[i]);
      unchecked {
        i++;
      }
    }
  }

  function clear() public onlyOwner {
    address[] memory addrs = dump();
    for (uint256 i = 0; i < addrs.length; i++) {
      whitelist.remove(addrs[i]);
    }
  }

  function freeze() public onlyOwner {
    isFrozen = true;
  }

  function unfreeze() public onlyOwner {
    isFrozen = false;
  }

  /// @dev Show all whitelisted addresses
  function dump() public view onlyOwner returns (address[] memory) {
    return whitelist.values();
  }
}