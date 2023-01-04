// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import { IAxelarGateway } from './IAxelarGateway.sol';

abstract contract IAxelarExecutable {
    error NotApprovedByGateway();

    IAxelarGateway public gateway;

    constructor(address gateway_) {
        gateway = IAxelarGateway(gateway_);
    }

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external {
        bytes32 payloadHash = keccak256(payload);
        if (!gateway.validateContractCall(commandId, sourceChain, sourceAddress, payloadHash)) revert NotApprovedByGateway();
        _execute(sourceChain, sourceAddress, payload);
    }

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external {
        bytes32 payloadHash = keccak256(payload);
        if (!gateway.validateContractCallAndMint(commandId, sourceChain, sourceAddress, payloadHash, tokenSymbol, amount))
            revert NotApprovedByGateway();

        _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
    }

    function _execute(
        string memory sourceChain,
        string memory sourceAddress,
        bytes calldata payload
    ) internal virtual {}

    function _executeWithToken(
        string memory sourceChain,
        string memory sourceAddress,
        bytes calldata payload,
        string memory tokenSymbol,
        uint256 amount
    ) internal virtual {}
}