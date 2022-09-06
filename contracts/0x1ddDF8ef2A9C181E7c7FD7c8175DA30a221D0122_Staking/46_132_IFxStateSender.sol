// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data) external;
}