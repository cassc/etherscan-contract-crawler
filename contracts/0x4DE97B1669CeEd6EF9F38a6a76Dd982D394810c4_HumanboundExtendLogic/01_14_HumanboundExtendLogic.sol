// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@violetprotocol/extendable/extensions/extend/ExtendLogic.sol";
import { HumanboundPermissionState, HumanboundPermissionStorage } from "../../storage/HumanboundPermissionStorage.sol";

contract HumanboundExtendLogic is ExtendLogic {
    event OperatorInitialised(address initialOperator);

    modifier onlyOperator() virtual {
        initialise();

        HumanboundPermissionState storage state = HumanboundPermissionStorage._getState();

        // Set the operator to the transaction sender if operator has not been initialised
        if (state.operator == address(0x0)) {
            state.operator = _lastCaller();
            emit OperatorInitialised(_lastCaller());
        }

        require(_lastCaller() == state.operator, "HumanboundExtendLogic: unauthorised");
        _;
    }

    // Overrides the previous implementation of modifier to remove owner checks
    modifier onlyOwnerOrSelf() override {
        _;
    }

    function extend(address extension) public override onlyOperator {
        super.extend(extension);
    }
}