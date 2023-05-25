// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../libs/TimestampStorage.sol";

contract TimestampStorageTest {
    using TimestampStorage for TimestampStorage.Storage;

    TimestampStorage.Storage private ts;

    function set(uint256 index, uint40 timestamp) external {
        ts.set(index, timestamp);
    }

    function get(uint256 index) external view returns(uint256) {
        return ts.get(index);
    }
}