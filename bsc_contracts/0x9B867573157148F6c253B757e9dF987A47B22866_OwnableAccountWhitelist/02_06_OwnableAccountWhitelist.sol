// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {Ownable} from "../../lib/Ownable.sol";
import {EnumerableSet} from "../../lib/EnumerableSet.sol";

import {IAccountWhitelist} from "./IAccountWhitelist.sol";

contract OwnableAccountWhitelist is IAccountWhitelist, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _accounts;

    function getWhitelistedAccounts() external view returns (address[] memory) {
        return _accounts.values();
    }

    function isAccountWhitelisted(address account_) external view returns (bool) {
        return _accounts.contains(account_);
    }

    function addAccountToWhitelist(address account_) external onlyOwner {
        require(_accounts.add(account_), "WL: account already included");
        emit AccountAdded(account_);
    }

    function removeAccountFromWhitelist(address account_) external onlyOwner {
        require(_accounts.remove(account_), "WL: account already excluded");
        emit AccountRemoved(account_);
    }
}