// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IActionMsgReceiver {
    function onAction(bytes4 action, bytes memory message) external;
}