// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPolygonZkEVMBridge {
    function bridgeMessage(
        uint32 destinationNetwork,
        address destinationAddress,
        bool forceUpdateGlobalExitRoot,
        bytes calldata metadata
    ) external payable;
}