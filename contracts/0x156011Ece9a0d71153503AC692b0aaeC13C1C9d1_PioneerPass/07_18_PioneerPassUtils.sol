// SPDX-License-Identifier: MIT
// Creator: @casareafer at 1TM.io

pragma solidity ^0.8.17;

contract PioneerPassUtils {
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
}