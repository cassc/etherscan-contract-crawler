//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/IValidator.sol";

contract Validator is Ownable, IValidator {
    mapping (address => bool) private _validators;

    modifier onlyValidator() {
        require(_validators[msg.sender], "not a validator");
        _;
    }

    function allowValidator(address validatorAddress) public override onlyOwner {
        require(!_validators[validatorAddress], "already a validator");
        _validators[validatorAddress] = true;
    }

    function disallowValidator(address validatorAddress) public override onlyOwner {
        require(_validators[validatorAddress], "already not a validator");
        _validators[validatorAddress] = false;
    }
}