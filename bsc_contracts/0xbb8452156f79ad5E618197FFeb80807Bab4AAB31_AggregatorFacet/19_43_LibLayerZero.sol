// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {DataTransferType} from "./LibDataTransfer.sol";
import {ILayerZero} from "../interfaces/layer-zero/ILayerZero.sol";
import {AppStorage, LayerZeroSettings, LibMagpieAggregator} from "../libraries/LibMagpieAggregator.sol";
import {DataTransferInProtocol, LibDataTransfer, TransferKey} from "./LibDataTransfer.sol";
import "../libraries/LibError.sol";

struct LayerZeroDataTransferInData {
    uint256 fee;
}

struct LayerZeroDataTransferOutData {
    uint16 senderNetworkId;
    bytes32 senderAddress;
    uint64 coreSequence;
}

library LibLayerZero {
    event UpdateLayerZeroSettings(address indexed sender, LayerZeroSettings layerZeroSettings);

    function updateSettings(LayerZeroSettings memory layerZeroSettings) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.layerZeroSettings = layerZeroSettings;

        emit UpdateLayerZeroSettings(msg.sender, layerZeroSettings);
    }

    event AddLayerZeroChainIds(address indexed sender, uint16[] networkIds, uint16[] chainIds);

    function addLayerZeroChainIds(uint16[] memory networkIds, uint16[] memory chainIds) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        uint256 i;
        uint256 l = networkIds.length;
        for (i = 0; i < l; ) {
            s.layerZeroChainIds[networkIds[i]] = chainIds[i];

            unchecked {
                i++;
            }
        }

        emit AddLayerZeroChainIds(msg.sender, networkIds, chainIds);
    }

    event AddLayerZeroNetworkIds(address indexed sender, uint16[] chainIds, uint16[] networkIds);

    function addLayerZeroNetworkIds(uint16[] memory chainIds, uint16[] memory networkIds) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        uint256 i;
        uint256 l = chainIds.length;
        for (i = 0; i < l; ) {
            s.layerZeroNetworkIds[chainIds[i]] = networkIds[i];

            unchecked {
                i++;
            }
        }

        emit AddLayerZeroNetworkIds(msg.sender, chainIds, networkIds);
    }

    function decodeDataTransferOutPayload(bytes memory dataTransferOutPayload)
        private
        pure
        returns (LayerZeroDataTransferOutData memory dataTransferOutData)
    {
        assembly {
            mstore(dataTransferOutData, shr(240, mload(add(dataTransferOutPayload, 32))))
            mstore(add(dataTransferOutData, 32), mload(add(dataTransferOutPayload, 34)))
            mstore(add(dataTransferOutData, 64), shr(192, mload(add(dataTransferOutPayload, 66))))
        }
    }

    function decodeDataTransferInPayload(bytes memory dataTransferInPayload)
        internal
        pure
        returns (LayerZeroDataTransferInData memory dataTransferInData)
    {
        assembly {
            mstore(dataTransferInData, mload(add(dataTransferInPayload, 32)))
        }
    }

    function dataTransfer(bytes memory payload, DataTransferInProtocol memory protocol) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        LayerZeroDataTransferInData memory dataTransferInData = decodeDataTransferInPayload(protocol.payload);

        ILayerZero(s.layerZeroSettings.routerAddress).send{value: dataTransferInData.fee}(
            s.layerZeroChainIds[protocol.networkId],
            abi.encodePacked(s.magpieAggregatorAddresses[protocol.networkId]),
            payload,
            payable(msg.sender),
            address(0x0),
            "0x"
        );
    }

    function getPayload(bytes memory dataTransferOutPayload) internal view returns (bytes memory extendedPayload) {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        LayerZeroDataTransferOutData memory dataTransferOutData = decodeDataTransferOutPayload(dataTransferOutPayload);

        extendedPayload = s.payloads[uint16(DataTransferType.LayerZero)][dataTransferOutData.senderNetworkId][
            dataTransferOutData.senderAddress
        ][dataTransferOutData.coreSequence];

        if (extendedPayload.length == 0) {
            revert InvalidPayload();
        }
    }

    function registerPayload(TransferKey memory transferKey, bytes memory extendedPayload) private {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        if (
            s
            .payloads[uint16(DataTransferType.LayerZero)][transferKey.networkId][transferKey.senderAddress][
                transferKey.coreSequence
            ].length > 0
        ) {
            revert SequenceHasPayload();
        }

        s.payloads[uint16(DataTransferType.LayerZero)][transferKey.networkId][transferKey.senderAddress][
                transferKey.coreSequence
            ] = extendedPayload;
    }

    function lzReceive(
        uint16 senderChainId,
        bytes32 senderAddress,
        bytes memory extendedPayload
    ) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();
        TransferKey memory transferKey = LibDataTransfer.getTransferKey(extendedPayload);

        LibDataTransfer.validateTransfer(s.layerZeroNetworkIds[senderChainId], senderAddress, transferKey);

        registerPayload(transferKey, extendedPayload);
    }

    function enforce() internal view {
        AppStorage storage s = LibMagpieAggregator.getStorage();
        if (msg.sender != s.layerZeroSettings.routerAddress) {
            revert InvalidSender();
        }
    }
}