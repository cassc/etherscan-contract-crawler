// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;
import "../interfaces/IMagpieBridge.sol";

library LibBytes {
    using LibBytes for bytes;

    function toAddress(bytes memory self, uint256 start)
        internal
        pure
        returns (address)
    {
        return address(uint160(uint256(self.toBytes32(start))));
    }

    function toBool(bytes memory self, uint256 start)
        internal
        pure
        returns (bool)
    {
        return self.toUint8(start) == 1 ? true : false;
    }

    function toUint8(bytes memory self, uint256 start)
        internal
        pure
        returns (uint8)
    {
        require(self.length >= start + 1, "LibBytes: toUint8 outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(self, 0x1), start))
        }

        return tempUint;
    }

    function toUint16(bytes memory self, uint256 start)
        internal
        pure
        returns (uint16)
    {
        require(self.length >= start + 2, "LibBytes: toUint16 outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(self, 0x2), start))
        }

        return tempUint;
    }

    function toUint24(bytes memory self, uint256 start)
        internal
        pure
        returns (uint24)
    {
        require(self.length >= start + 3, "LibBytes: toUint24 outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(self, 0x3), start))
        }

        return tempUint;
    }

    function toUint64(bytes memory self, uint256 start)
        internal
        pure
        returns (uint64)
    {
        require(self.length >= start + 8, "LibBytes: toUint64 outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(self, 0x8), start))
        }

        return tempUint;
    }

    function toUint256(bytes memory self, uint256 start)
        internal
        pure
        returns (uint256)
    {
        require(self.length >= start + 32, "LibBytes: toUint256 outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(self, 0x20), start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory self, uint256 start)
        internal
        pure
        returns (bytes32)
    {
        require(self.length >= start + 32, "LibBytes: toBytes32 outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(self, 0x20), start))
        }

        return tempBytes32;
    }

    function toBridgeType(bytes memory self, uint256 start)
        internal
        pure
        returns (IMagpieBridge.BridgeType)
    {
        return self.toUint8(start) == 0 ? IMagpieBridge.BridgeType.Wormhole : IMagpieBridge.BridgeType.Hyphen;
    }

    function parse(bytes memory self)
        internal
        pure
        returns (IMagpieBridge.ValidationOutPayload memory payload)
    {
        uint256 i = 0;

        payload.fromAssetAddress = self.toAddress(i);
        i += 32;

        payload.toAssetAddress = self.toAddress(i);
        i += 32;

        payload.to = self.toAddress(i);
        i += 32;

        payload.recipientCoreAddress = self.toAddress(i);
        i += 32;

        payload.amountOutMin = self.toUint256(i);
        i += 32;

        payload.swapOutGasFee = self.toUint256(i);
        i += 32;

        payload.destGasTokenAmount = self.toUint256(i);
        i += 32;

        payload.destGasTokenAmountOutMin = self.toUint256(i);
        i += 32;

        payload.amountIn = self.toUint256(i);
        i += 32;

        payload.tokenSequence = self.toUint64(i);
        i += 8;

        payload.senderIntermediaryDecimals = self.toUint8(i);
        i += 1;

        payload.senderNetworkId = self.toUint8(i);
        i += 1;

        payload.recipientNetworkId = self.toUint8(i);
        i += 1;

        payload.bridgeType = self.toBridgeType(i);
        i += 1;

        
        require(self.length == i, "LibBytes: payload is invalid");
    }
}