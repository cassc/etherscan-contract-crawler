// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {LibBytes} from "../libraries/LibBytes.sol";
import {AppStorage, BridgeType, DataTransferType, LibMagpieAggregator} from "../libraries/LibMagpieAggregator.sol";
import {LibTransaction, Transaction} from "../bridge/LibTransaction.sol";
import {LibLayerZero} from "./LibLayerZero.sol";
import {LibWormhole} from "./LibWormhole.sol";

struct DataTransferInProtocol {
    uint16 networkId;
    DataTransferType dataTransferType;
    bytes payload;
}

struct DataTransferInArgs {
    DataTransferInProtocol[] protocols;
    bytes payload;
}

struct DataTransferOutArgs {
    DataTransferType dataTransferType;
    bytes payload;
}

struct TransferKey {
    uint16 networkId;
    bytes32 senderAddress;
    uint64 coreSequence;
}

error InvalidDataTransferType();
error DataTransferInvalidProtocol();
error InvalidTransfer();

library LibDataTransfer {
    using LibBytes for bytes;

    function getExtendedPayload(bytes memory payload, TransferKey memory transferKey)
        private
        pure
        returns (bytes memory)
    {
        bytes memory transferKeyPayload = new bytes(42);

        assembly {
            mstore(add(transferKeyPayload, 32), shl(240, mload(transferKey)))
            mstore(add(transferKeyPayload, 34), mload(add(transferKey, 32)))
            mstore(add(transferKeyPayload, 66), shl(192, mload(add(transferKey, 64))))
        }

        return transferKeyPayload.concat(payload);
    }

    function getTransferKey(bytes memory extendedPayload) internal pure returns (TransferKey memory transferKey) {
        assembly {
            mstore(transferKey, shr(240, mload(add(extendedPayload, 32))))
            mstore(add(transferKey, 32), mload(add(extendedPayload, 34)))
            mstore(add(transferKey, 64), shr(192, mload(add(extendedPayload, 66))))
        }
    }

    function validateTransfer(
        uint16 networkId,
        bytes32 senderAddress,
        TransferKey memory transferKey
    ) internal view {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        if (
            networkId == 0 ||
            senderAddress != s.magpieAggregatorAddresses[networkId] ||
            senderAddress != transferKey.senderAddress ||
            networkId != transferKey.networkId
        ) {
            revert InvalidTransfer();
        }
    }

    function getOriginalPayload(bytes memory extendedPayload) private pure returns (bytes memory) {
        return extendedPayload.slice(42, extendedPayload.length - 42);
    }

    function dataTransfer(DataTransferInArgs memory dataTransferInArgs)
        internal
        returns (TransferKey memory transferKey)
    {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.coreSequence += 1;
        transferKey = TransferKey({
            networkId: s.networkId,
            senderAddress: bytes32(uint256(uint160(address(this)))),
            coreSequence: s.coreSequence
        });
        bytes memory extendedPayload = getExtendedPayload(dataTransferInArgs.payload, transferKey);

        bool wormholeUsed = false;
        uint256 pl = dataTransferInArgs.protocols.length;
        uint16 lastNetworkId = 0;
        for (uint256 p; p < pl; ) {
            if (p == 0 || uint16(dataTransferInArgs.protocols[p].networkId) > lastNetworkId) {
                lastNetworkId = uint16(dataTransferInArgs.protocols[p].networkId);
            } else {
                revert DataTransferInvalidProtocol();
            }

            if (dataTransferInArgs.protocols[p].dataTransferType == DataTransferType.Wormhole && !wormholeUsed) {
                wormholeUsed = true;
                LibWormhole.dataTransfer(extendedPayload);
            } else if (dataTransferInArgs.protocols[p].dataTransferType == DataTransferType.LayerZero) {
                LibLayerZero.dataTransfer(extendedPayload, dataTransferInArgs.protocols[p]);
            } else {
                revert InvalidDataTransferType();
            }

            unchecked {
                p++;
            }
        }
    }

    function getPayload(DataTransferOutArgs memory dataTransferOutArgs)
        internal
        view
        returns (TransferKey memory transferKey, bytes memory payload)
    {
        if (dataTransferOutArgs.dataTransferType == DataTransferType.Wormhole) {
            payload = LibWormhole.getPayload(dataTransferOutArgs.payload);
        } else if (dataTransferOutArgs.dataTransferType == DataTransferType.LayerZero) {
            payload = LibLayerZero.getPayload(dataTransferOutArgs.payload);
        } else {
            revert InvalidDataTransferType();
        }

        transferKey = getTransferKey(payload);
        payload = getOriginalPayload(payload);
    }
}