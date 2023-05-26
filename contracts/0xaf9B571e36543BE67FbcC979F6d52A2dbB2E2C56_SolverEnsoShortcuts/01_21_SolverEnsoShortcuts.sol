// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.17;

import {VM} from "enso-weiroll/VM.sol";
import {MinimalWallet} from "shortcuts-contracts/wallet/MinimalWallet.sol";
import {AccessController} from "shortcuts-contracts/access/AccessController.sol";

contract SolverEnsoShortcuts is VM, MinimalWallet, AccessController {
    address private constant settlement = 0x9008D19f58AAbD9eD0D60971565AA8510560ab41;

    constructor(address owner) {
        _setPermission(OWNER_ROLE, owner, true);
    }

    // @notice Execute a shortcut from a solver
    // @param commands An array of bytes32 values that encode calls
    // @param state An array of bytes that are used to generate call data for each command
    function executeShortcut(bytes32[] calldata commands, bytes[] calldata state)
        external
        payable
        returns (bytes[] memory)
    {
        // we could use the AccessController here to check if the msg.sender is the settlement address
        // but as it's a hot path we do a less gas intensive check
        if (msg.sender != settlement) revert NotPermitted();
        return _execute(commands, state);
    }
}