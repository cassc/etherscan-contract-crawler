// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {VM} from "@ensofinance/weiroll/contracts/VM.sol";

contract EnsoWallet is VM {
    address public caller;
    bool public initialized;

    // Already initialized
    error AlreadyInit();
    // Not caller
    error NotCaller();
    // Invalid address
    error InvalidAddress();

    function initialize(
        address caller_,
        bytes32[] calldata commands,
        bytes[] calldata state
    ) external payable {
        if (initialized) revert AlreadyInit();
        caller = caller_;
        if (commands.length != 0) {
            _execute(commands, state);
        }
    }

    function execute(bytes32[] calldata commands, bytes[] calldata state)
        external
        payable
        returns (bytes[] memory returnData)
    {
        if (msg.sender != caller) revert NotCaller();
        returnData = _execute(commands, state);
    }

    receive() external payable {}
}