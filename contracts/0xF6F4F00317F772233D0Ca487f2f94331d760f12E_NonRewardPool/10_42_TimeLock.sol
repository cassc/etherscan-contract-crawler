// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

/**
 Contract which implements locking of functions via a notLocked modifier
 Functions are locked per address.
 */
contract TimeLock {
    // how many seconds are the functions locked for
    uint256 private constant TIME_LOCK_SECONDS = 60; // 1 minute
    // last timestamp for which this address is timelocked
    mapping(address => uint256) public lastLockedTimestamp;

    function lock(address _address) internal {
        lastLockedTimestamp[_address] = block.timestamp + TIME_LOCK_SECONDS;
    }

    modifier notLocked(address lockedAddress) {
        require(
            lastLockedTimestamp[lockedAddress] <= block.timestamp,
            "Address is temporarily locked"
        );
        _;
    }
}