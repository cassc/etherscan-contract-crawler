// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMFLocks {
    function addLock(
        address _investor,
        uint256 _amount,
        uint256 _dateStart,
        uint256 _duration
    ) external;

    function withdraw() external;
}