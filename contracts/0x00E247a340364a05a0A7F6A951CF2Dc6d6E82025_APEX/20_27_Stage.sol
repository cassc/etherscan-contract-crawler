// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IStage.sol";
import "./APEXAccessControl.sol";

import {Errors} from "../libraries/Errors.sol";

contract Stage is IStage, APEXAccessControl {
    bytes32 constant WARM_UP = keccak256("WARM_UP");
    bytes32 constant PRE_MINT = keccak256("PRE_MINT");
    bytes32 constant FORMAL_MINT = keccak256("FORMAL_MINT");

    bytes32 private _currentStage = WARM_UP;

    constructor() {}

    function moveToNextStage(
        bytes32 currentStage,
        bytes32 nextStage
    ) external onlyRole(BUSINESS_MANAGER) {
        if (currentStage != _currentStage) {
            revert Errors.NotCurrentStage(currentStage);
        }

        if (currentStage == WARM_UP) {
            if (nextStage != PRE_MINT) {
                revert Errors.NotNextStage(nextStage);
            }
        } else if (currentStage == PRE_MINT) {
            if (nextStage != FORMAL_MINT) {
                revert Errors.NotNextStage(nextStage);
            }
        } else if (currentStage == FORMAL_MINT) {
            revert Errors.NoMoreStage();
        }

        _currentStage = nextStage;
    }

    function getCurrentStage() public view returns (bytes32) {
        return _currentStage;
    }
}