// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface IVRFSubcriber
{
    function _vrfCallback(uint256 requestId, uint256[] memory randomWords) external;
}