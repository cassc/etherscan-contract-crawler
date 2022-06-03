// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

interface IEthCrossChainManager {
    function crossChain(
        uint64 _toChainId,
        bytes calldata _toContract,
        bytes calldata _method,
        bytes calldata _txData
    ) external returns (bool);
}