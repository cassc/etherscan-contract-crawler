// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IValidatable {
    function validateContract() external view returns (string memory);
}