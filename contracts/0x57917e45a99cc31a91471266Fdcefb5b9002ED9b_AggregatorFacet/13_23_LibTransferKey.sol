// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

struct TransferKey {
    uint16 networkId;
    bytes32 senderAddress;
    uint64 swapSequence;
}

error InvalidTransferKey();

library LibTransferKey {
    function encode(TransferKey memory transferKey) internal pure returns (bytes memory) {
        bytes memory payload = new bytes(42);

        assembly {
            mstore(add(payload, 32), shl(240, mload(transferKey)))
            mstore(add(payload, 34), mload(add(transferKey, 32)))
            mstore(add(payload, 66), shl(192, mload(add(transferKey, 64))))
        }

        return payload;
    }

    function decode(bytes memory payload) internal pure returns (TransferKey memory transferKey) {
        assembly {
            mstore(transferKey, shr(240, mload(add(payload, 32))))
            mstore(add(transferKey, 32), mload(add(payload, 34)))
            mstore(add(transferKey, 64), shr(192, mload(add(payload, 66))))
        }
    }

    function validate(TransferKey memory self, TransferKey memory transferKey) internal pure {
        if (
            self.networkId != transferKey.networkId ||
            self.senderAddress != transferKey.senderAddress ||
            self.swapSequence != transferKey.swapSequence
        ) {
            revert InvalidTransferKey();
        }
    }
}