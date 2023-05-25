// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library TimestampStorage {
    struct Storage {
        mapping(uint256 => uint256) _data;
    }

    uint256 private constant BIT_MASK = 0xFFFFFFFFFF;
    uint256 private constant BIT_SIZE = 40;
    uint256 private constant MAX_SIZE = 6;

    function get(
        Storage storage s,
        uint256 index
    ) internal view returns (uint256) {
        uint256 bucket = index % MAX_SIZE;
        return (s._data[bucket] >> ((BIT_SIZE * index) / MAX_SIZE)) & BIT_MASK;
    }

    function set(Storage storage s, uint256 index, uint40 timestamp) internal {
        uint256 bucket = index % MAX_SIZE;
        uint256 maskdata = s._data[bucket] &
            ~(BIT_MASK << ((BIT_SIZE * index) / MAX_SIZE));
        uint256 setdata = (timestamp & BIT_MASK) <<
            ((BIT_SIZE * index) / MAX_SIZE);
        s._data[bucket] = maskdata | setdata;
    }
}