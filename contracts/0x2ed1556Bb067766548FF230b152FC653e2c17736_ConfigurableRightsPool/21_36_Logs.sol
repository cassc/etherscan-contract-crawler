// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

contract Logs {
    event LOG_CALL(bytes4 indexed sig, address indexed caller, bytes data) anonymous;

    modifier _logs_() {
        emit LOG_CALL(msg.sig, msg.sender, msg.data);
        _;
    }
}