// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface INameValidator {
    function validateName(string memory name) external pure returns (uint256);
}