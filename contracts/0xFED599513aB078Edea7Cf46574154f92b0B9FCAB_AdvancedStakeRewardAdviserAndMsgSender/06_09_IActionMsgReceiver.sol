// SPDX-License-Identifier: MIT
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

interface IActionMsgReceiver {
    function onAction(bytes4 action, bytes memory message) external;
}