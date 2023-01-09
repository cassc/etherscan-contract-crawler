// SPDX-License-Identifier: MIT
// contracts/modules/Whitelist.sol

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract Whitelist is AccessControlEnumerable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _whitelist;

    event WhitelistEvent(address indexed account, bool enable);

    function setWhitelist(address[] memory accounts, bool enable) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Whitelist: Must have admin role to set excluded fee address");

        for (uint256 i = 0; i < accounts.length; i++) {
            setWhitelist(accounts[i], enable);
        }
    }

    function setWhitelist(address account, bool enable) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Whitelist: Must have admin role to set white address");

        if (enable) {
            require(!_whitelist.contains(account), "Whitelist: Address is exist");
            _whitelist.add(account);

            emit WhitelistEvent(account, true);
        } else {
            require(_whitelist.contains(account), "Whitelist: Address not exist");
            _whitelist.remove(account);

            emit WhitelistEvent(account, false);
        }
    }

    function isWhitelist(address account) public view returns (bool) {
        return _whitelist.contains(account);
    }
}