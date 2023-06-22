// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface ITwoWeeksNotice {
    function getStakeState(address account) external view returns (uint64, uint64, uint64, uint64);

    function getAccumulated(address account) external view returns (uint128, uint128);
}