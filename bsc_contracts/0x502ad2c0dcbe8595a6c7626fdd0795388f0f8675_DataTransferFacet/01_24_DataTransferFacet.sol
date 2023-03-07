// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {LibDiamond} from "../../diamond/LibDiamond.sol";
import {LayerZeroSettings, WormholeSettings} from "../../libraries/LibMagpieAggregator.sol";
import {LibDataTransfer} from "../LibDataTransfer.sol";
import {LibLayerZero} from "../LibLayerZero.sol";
import {LibWormhole} from "../LibWormhole.sol";
import {IDataTransfer} from "../interfaces/IDataTransfer.sol";

contract DataTransferFacet is IDataTransfer {
    function updateLayerZeroSettings(LayerZeroSettings calldata layerZeroSettings) external override {
        LibDiamond.enforceIsContractOwner();
        LibLayerZero.updateSettings(layerZeroSettings);
    }

    function addLayerZeroChainIds(uint16[] calldata networkIds, uint16[] calldata chainIds) external override {
        LibDiamond.enforceIsContractOwner();
        LibLayerZero.addLayerZeroChainIds(networkIds, chainIds);
    }

    function addLayerZeroNetworkIds(uint16[] calldata chainIds, uint16[] calldata networkIds) external override {
        LibDiamond.enforceIsContractOwner();
        LibLayerZero.addLayerZeroNetworkIds(chainIds, networkIds);
    }

    function updateWormholeSettings(WormholeSettings calldata wormholeSettings) external override {
        LibDiamond.enforceIsContractOwner();
        LibWormhole.updateSettings(wormholeSettings);
    }

    function addWormholeNetworkIds(uint16[] calldata chainIds, uint16[] calldata networkIds) external override {
        LibDiamond.enforceIsContractOwner();
        LibWormhole.addWormholeNetworkIds(chainIds, networkIds);
    }

    function lzReceive(
        uint16 senderChainId,
        bytes calldata senderAddress,
        uint64,
        bytes calldata extendedPayload
    ) external override {
        LibLayerZero.enforce();
        LibLayerZero.lzReceive(senderChainId, bytes32(senderAddress), extendedPayload);
    }
}