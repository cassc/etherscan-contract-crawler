// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "./IVRFSubcriber.sol";

interface IVRFKeeper
{
    function requestRandomness(uint32 numWords, IVRFSubcriber subscriber) external returns (uint256);
}