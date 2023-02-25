// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IModuleMetadata {
    function moduleId() external pure returns (string memory);
    function moduleVersion() external pure returns (uint256);
}