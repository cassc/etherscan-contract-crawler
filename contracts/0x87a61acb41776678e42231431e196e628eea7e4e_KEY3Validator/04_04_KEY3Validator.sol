// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IKEY3Validator.sol";

contract KEY3Validator is IKEY3Validator, Ownable {
    mapping(IKEY3Validator => bool) public validatorMapping;
    IKEY3Validator[] public validators;
    mapping(bytes32 => bool) private _reserveds;

    function validate(string memory name_) public view returns (bool) {
        bytes32 hash = keccak256(bytes(name_));
        if (_reserveds[hash]) {
            return false;
        }
        for (uint i = 0; i < validators.length; i++) {
            IKEY3Validator validator = validators[i];
            if (
                address(validator) != address(0) && validatorMapping[validator]
            ) {
                if (!validator.validate(name_)) {
                    return false;
                }
            }
        }

        return true;
    }

    function addValidator(IKEY3Validator validator_) public onlyOwner {
        validatorMapping[validator_] = true;
        (bool exist, ) = _exists(validator_);
        if (!exist) {
            validators.push(validator_);
        }
    }

    function _exists(IKEY3Validator validator_)
        internal
        view
        returns (bool, uint)
    {
        for (uint i = 0; i < validators.length; i++) {
            if (validators[i] == validator_) {
                return (true, i);
            }
        }

        return (false, 0);
    }

    function removeValidator(IKEY3Validator validator_) public onlyOwner {
        validatorMapping[validator_] = false;
    }

    function addToReserveds(string[] memory names_) public onlyOwner {
        for (uint256 i = 0; i < names_.length; i++) {
            bytes32 hash = keccak256(bytes(names_[i]));
            _reserveds[hash] = true;
        }
    }

    function removeFromReserveds(string[] memory names_) public onlyOwner {
        for (uint256 i = 0; i < names_.length; i++) {
            bytes32 hash = keccak256(bytes(names_[i]));
            delete _reserveds[hash];
        }
    }
}