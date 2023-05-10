// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library RegisterValidatorErrors {
    error InvalidNumberOfValidators(
        uint256 validatorsAccountLength,
        uint256 expectedValidatorsAccountLength
    );
}