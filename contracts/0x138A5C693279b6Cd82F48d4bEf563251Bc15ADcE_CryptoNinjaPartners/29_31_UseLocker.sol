// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./ILocker.sol";

abstract contract UseLocker {
    ILocker public locker;
    modifier whenNotLocked(uint256 tokenId) {
        require(
            !isLocked(tokenId),
            "The token is loked now."
        );
        _;
    }

    function isLocked(uint256 tokenId) public virtual view returns(bool) {
        return address(locker) != address(0) && locker.isLocked(address(this), tokenId);
    }

    function _setLocker(address value) internal virtual {
        locker = ILocker(value);
    }

    function setLocker(address value) virtual external;
}