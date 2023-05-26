//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IValidator {
    function allowValidator(address validatorAddress) external;
    function disallowValidator(address validatorAddress) external;
}