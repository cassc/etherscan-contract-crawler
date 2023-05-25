// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAwakenedZoofrenzVRF {
    function requestRandomWords() external returns (uint256);

    function getResult(uint256 requestId) external view returns (uint256);
}