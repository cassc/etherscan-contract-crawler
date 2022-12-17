// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/contracts/utils/ContextUpgradeable.sol";

import "./Manageable.sol";

contract Whitelistable is Manageable {
    mapping(address => bool) whitelisted_;

    modifier onlyWhitelisted() {
        require(whitelisted_[_msgSender()], "Whitelistable: only allowed for whitelisted addresses");
        _;
    }

    event Whitelist(address indexed address_);
    event RevokeWhitelist(address indexed address_);

    function __Whitelistable_init(address manager_) internal virtual onlyInitializing {
        __Manageable_init(manager_);
    }

    function whitelistAddress(address address_) public virtual onlyManager {
        whitelisted_[address_] = true;
        emit Whitelist(address_);
    }

    function revokeWhitelist(address address_) public virtual onlyManager {
        whitelisted_[address_] = false;
        emit RevokeWhitelist(address_);
    }

    function isWhitelisted(address address_) public view returns (bool) {
        return whitelisted_[address_];
    }
}