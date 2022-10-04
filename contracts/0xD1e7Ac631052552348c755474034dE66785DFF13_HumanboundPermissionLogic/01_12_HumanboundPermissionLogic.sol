// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { HumanboundPermissionState, HumanboundPermissionStorage } from "../../storage/HumanboundPermissionStorage.sol";
import "./IHumanboundPermissionLogic.sol";

contract HumanboundPermissionLogic is HumanboundPermissionExtension {
    function updateOperator(address newOperator) external onlyOwner {
        HumanboundPermissionState storage state = HumanboundPermissionStorage._getState();
        state.operator = newOperator;

        emit OperatorUpdated(newOperator);
    }

    function getOperator() external view returns (address) {
        HumanboundPermissionState storage state = HumanboundPermissionStorage._getState();
        return state.operator;
    }
}