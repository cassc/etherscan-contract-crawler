// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ITransferStrategy {
    function canTransfer(
        address,
        address,
        uint256
    ) external view returns (bool);
}