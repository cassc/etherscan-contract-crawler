// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ITransferController {
    function canTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) external view returns (bool);
}