// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {LibDataTransfer} from "./LibDataTransfer.sol";
import {AppStorage, LibMagpieAggregator, WormholeSettings} from "../libraries/LibMagpieAggregator.sol";
import {IWormholeCore} from "../interfaces/wormhole/IWormholeCore.sol";
import {LibDataTransfer, TransferKey} from "./LibDataTransfer.sol";

library LibWormhole {
    event UpdateWormholeSettings(address indexed sender, WormholeSettings wormholeSettings);

    function updateSettings(WormholeSettings memory wormholeSettings) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.wormholeSettings = wormholeSettings;

        emit UpdateWormholeSettings(msg.sender, wormholeSettings);
    }

    event AddWormholeNetworkIds(address indexed sender, uint16[] chainIds, uint16[] networkIds);

    function addWormholeNetworkIds(uint16[] memory chainIds, uint16[] memory networkIds) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        uint256 i;
        uint256 l = chainIds.length;
        for (i = 0; i < l; ) {
            s.wormholeNetworkIds[chainIds[i]] = networkIds[i];

            unchecked {
                i++;
            }
        }

        emit AddWormholeNetworkIds(msg.sender, chainIds, networkIds);
    }

    function dataTransfer(bytes memory payload) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        uint64 wormholeCoreSequence = IWormholeCore(s.wormholeSettings.bridgeAddress).publishMessage(
            uint32(block.timestamp % 2**32),
            payload,
            s.wormholeSettings.consistencyLevel
        );

        s.wormholeCoreSequences[s.coreSequence] = wormholeCoreSequence;
    }

    function getPayload(bytes memory dataTransferOutPayload) internal view returns (bytes memory extendedPayload) {
        AppStorage storage s = LibMagpieAggregator.getStorage();
        (IWormholeCore.VM memory vm, bool valid, string memory reason) = IWormholeCore(s.wormholeSettings.bridgeAddress)
            .parseAndVerifyVM(dataTransferOutPayload);
        require(valid, reason);

        TransferKey memory transferKey = LibDataTransfer.getTransferKey(vm.payload);

        LibDataTransfer.validateTransfer(s.wormholeNetworkIds[vm.emitterChainId], vm.emitterAddress, transferKey);

        extendedPayload = vm.payload;
    }
}