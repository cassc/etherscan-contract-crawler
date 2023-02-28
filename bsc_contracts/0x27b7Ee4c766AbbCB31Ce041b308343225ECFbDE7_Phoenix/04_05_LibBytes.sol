// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

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

    function toString(bytes memory self, uint256 start)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encode(self.toBytes32(start)));
    }

    function parseDepositInfo(bytes memory self)
        internal
        pure
        returns (
            address senderAddress,
            uint256 chainId,
            uint256 amount,
            string memory symbol
        )
    {
        uint256 i = 0;

        senderAddress = self.toAddress(i);
        i += 32;
        chainId = self.toUint256(i);
        i += 32;
        amount = self.toUint256(i);
        i += 32;
        symbol = self.toString(i);
        i += 32;
    }

    function parseSwapInfo(bytes memory self)
        internal
        pure
        returns (
            address senderAddress,
            address destinationAssetAddress,
            uint256 swappingChain,
            uint256 amountIn,
            uint256 amountOutMin,
            string memory symbol
        )
    {
        uint256 i = 0;

        senderAddress = self.toAddress(i);
        i += 32;

        destinationAssetAddress = self.toAddress(i);
        i += 32;

        swappingChain = self.toUint256(i);
        i += 32;

        amountIn = self.toUint256(i);
        i += 32;

        amountOutMin = self.toUint256(i);
        i += 32;

        symbol = self.toString(i);
        i += 32;
    }

    function parseSwappedInfo(bytes memory self)
        internal
        pure
        returns (
            address senderAddress,
            uint256 swappingChain,
            uint256 amountIn,
            address destinationAssetAddress,
            uint256 amountOut,
            string memory symbol
        )
    {
        uint256 i = 0;
        senderAddress = self.toAddress(i);
        i += 32;
        swappingChain = self.toUint256(i);
        i += 32;
        amountIn = self.toUint256(i);
        i += 32;
        destinationAssetAddress = self.toAddress(i);
        i += 32;
        amountOut = self.toUint256(i);
        i += 32;
        symbol = self.toString(i);
        i += 32;
    }
}