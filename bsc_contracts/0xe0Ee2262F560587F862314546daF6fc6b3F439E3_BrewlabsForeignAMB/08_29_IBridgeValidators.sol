// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IBridgeValidators {
    function isValidator(address _validator) external view returns (bool);
    function requiredSignatures() external view returns (uint256);
    function owner() external view returns (address);
}