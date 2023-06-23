// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../NFTCollection.sol";

abstract contract NFTCollectionLimitPerAccount is NFTCollection {
    uint256 public immutable limitPerAccount;

    error AccountLimitExceeded();

    constructor(uint256 _limitPerAccount) {
        limitPerAccount = _limitPerAccount;
    }

    modifier whenAccountLimitNotExceeded(uint256 _amount) {
        if (balanceOf(msg.sender) + _amount > limitPerAccount) {
            revert AccountLimitExceeded();
        }
        _;
    }

    function _mintAmount(uint256 _amount)
        internal
        virtual
        override
        whenAccountLimitNotExceeded(_amount)
    {
        super._mintAmount(_amount);
    }
}