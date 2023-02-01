// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IStructRandomnessManager {
    function TOKEN_OFFSET_SLOT() external view returns (bytes32);
    function randomness(address collection, bytes32 slot) external view returns (uint256);
    function requireRandomnessState(address collection, bytes32 slot, bool set) external view;
    function setWithPRNG(address collection, bytes32 slot) external payable;
    function setWithVRF(address collection, bytes32 slot) external payable;
}