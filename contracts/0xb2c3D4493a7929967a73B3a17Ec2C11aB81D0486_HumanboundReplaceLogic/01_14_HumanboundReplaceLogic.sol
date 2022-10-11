// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@violetprotocol/extendable/extensions/replace/StrictReplaceLogic.sol";
import { HumanboundPermissionState, HumanboundPermissionStorage } from "../../storage/HumanboundPermissionStorage.sol";

contract HumanboundReplaceLogic is StrictReplaceLogic {
    modifier onlyOperatorOrSelf() virtual {
        HumanboundPermissionState storage state = HumanboundPermissionStorage._getState();

        require(
            _lastCaller() == state.operator || _lastCaller() == address(this),
            "HumanboundReplaceLogic: unauthorised"
        );
        _;
    }

    // Overrides the previous implementation of modifier to remove owner checks
    modifier onlyOwner() override {
        _;
    }

    function replace(address oldExtension, address newExtension) public override onlyOperatorOrSelf {
        super.replace(oldExtension, newExtension);
    }
}