// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ITMAsLocker.sol";

abstract contract StakingCollection {
    ITMAsLocker public locker;
    modifier whenNotStaking(uint256 tokenId) {
        require(
            isLocked(tokenId) == false,
            "The token is loked now."
        );
        _;
    }

    function isLocked(uint256 tokenId) public virtual view returns(bool) {
        return address(locker) != address(0) && locker.isLocked(address(this), tokenId) == true;
    }

    function _setLocker(address value) internal virtual {
        locker = ITMAsLocker(value);
    }

    function setLocker(address value) virtual external;
}