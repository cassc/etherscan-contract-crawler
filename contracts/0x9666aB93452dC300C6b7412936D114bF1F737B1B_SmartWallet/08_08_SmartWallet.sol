// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {uncheckedInc} from "src/libs/Unchecked.sol";

/* solhint-disable avoid-low-level-calls */
contract SmartWallet is AccessControl {
    bytes32 public constant OWNER = keccak256("OWNER");

    constructor(address owner) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(OWNER, owner);
    }

    struct Call {
        address target;
        bytes callData;
    }

    function aggregate(Call[] memory calls) external onlyRole(OWNER) {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success,) = calls[i].target.call(calls[i].callData);
            require(success, "CALL_FAILED");
        }
    }
}