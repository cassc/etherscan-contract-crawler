// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IKEY3Validator {
    function validate(string memory name) external view returns (bool);
}