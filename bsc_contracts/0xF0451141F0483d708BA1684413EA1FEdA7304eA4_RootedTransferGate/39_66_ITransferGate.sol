// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

interface ITransferGate {
    function feeSplitter() external view returns (address);
    function handleTransfer(address msgSender, address from, address to, uint256 amount) external returns (uint256);
}