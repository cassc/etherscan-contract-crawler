// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

library BalanceStorage {
    struct Storage {
        mapping(uint256 => uint256) _data;
    }

    uint256 private constant BIT_MASK = 0xFFFF;
    uint256 private constant BIT_SIZE = 16;
    uint256 private constant MAX_SIZE = 16;

    function get(
        Storage storage s,
        uint256 index
    ) internal view returns (uint256) {
        uint256 bucket = index / MAX_SIZE;
        return (s._data[bucket] >> ((index % MAX_SIZE) * BIT_SIZE)) & BIT_MASK;
    }

    function set(Storage storage s, uint256 index, uint16 value) internal {
        uint256 bucket = index / MAX_SIZE;
        uint256 shiftSize = (index % MAX_SIZE) * BIT_SIZE;
        uint256 maskdata = s._data[bucket] & ~(BIT_MASK << shiftSize);
        uint256 setdata = (value & BIT_MASK) << shiftSize;
        s._data[bucket] = maskdata | setdata;
    }
}