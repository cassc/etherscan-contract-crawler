// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISourceAMB {
    function send(
        address recipient,
        uint16 recipientChainId,
        uint256 gasLimit,
        bytes calldata data
    ) external returns (bytes32);
}