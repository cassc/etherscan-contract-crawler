// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";

import "../libraries/Bytes32Address.sol";

import "./interfaces/IBlacklistableUpgradeable.sol";

abstract contract BlacklistableUpgradeable is
    IBlacklistableUpgradeable,
    ContextUpgradeable
{
    using Bytes32Address for address;
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;

    BitMapsUpgradeable.BitMap private _blacklisted;

    function __Blacklistable_init() internal onlyInitializing {}

    function __Blacklistable_init_unchained() internal onlyInitializing {}

    function setUserStatus(address account_, bool status)
        external
        virtual
        override;

    function isBlacklisted(address account_)
        public
        view
        override
        returns (bool)
    {
        return _blacklisted.get(account_.fillLast96Bits());
    }

    function _setUserStatus(address account_, bool status_) internal {
        _blacklisted.setTo(account_.fillFirst96Bits(), status_);
    }

    uint256[49] private __gap;
}