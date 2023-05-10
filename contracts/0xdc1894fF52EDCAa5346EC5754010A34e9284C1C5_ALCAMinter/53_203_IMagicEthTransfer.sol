// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IMagicEthTransfer {
    function depositEth(uint8 magic_) external payable;
}