// SPDX-License-Identifier: MIT
// contracts/modules/Blacklist.sol

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract Blacklist is AccessControlEnumerable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _blacklist;

    event BlacklistEvent(address indexed account, bool enable);

    function setBlacklist(address[] memory accounts, bool enable) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Blacklist: Must have admin role to set excluded fee address");

        for (uint256 i = 0; i < accounts.length; i++) {
            setBlacklist(accounts[i], enable);
        }
    }

    function setBlacklist(address account, bool enable) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Blacklist: Must have admin role to set black address");

        if (enable) {
            require(!_blacklist.contains(account), "Blacklist: Address is exist");
            _blacklist.add(account);

            emit BlacklistEvent(account, true);
        } else {
            require(_blacklist.contains(account), "Blacklist: Address not exist");
            _blacklist.remove(account);

            emit BlacklistEvent(account, false);
        }
    }

    function isBlacklist(address account) public view returns (bool) {
        return _blacklist.contains(account);
    }
}