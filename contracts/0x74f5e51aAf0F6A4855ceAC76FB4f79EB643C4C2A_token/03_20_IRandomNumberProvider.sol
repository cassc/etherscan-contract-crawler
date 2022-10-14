// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IRandomNumberProvider {
    function requestRandomNumber() external returns (bytes32 requestId);
    function requestRandomNumberWithCallback() external returns (bytes32);
    function isRequestComplete(bytes32 requestId) external view returns (bool isCompleted);
    function randomNumber(bytes32 requestId) external view returns (uint256 randomNum);
    function setAuth(address user, bool grant) external;
}