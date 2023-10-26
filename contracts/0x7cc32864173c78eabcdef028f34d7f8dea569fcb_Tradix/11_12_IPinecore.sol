// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IPineCore {
    function depositEth(bytes calldata _data) external payable;
}