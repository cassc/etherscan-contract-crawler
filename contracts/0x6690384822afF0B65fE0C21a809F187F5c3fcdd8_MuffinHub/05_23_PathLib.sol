// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

library PathLib {
    uint256 internal constant ADDR_BYTES = 20;
    uint256 internal constant ADDR_UINT16_BYTES = ADDR_BYTES + 2;
    uint256 internal constant PATH_MAX_BYTES = ADDR_UINT16_BYTES * 256 + ADDR_BYTES; // 256 pools (i.e. 5652 bytes)

    function invalid(bytes memory path) internal pure returns (bool) {
        unchecked {
            return
                path.length > PATH_MAX_BYTES ||
                path.length <= ADDR_BYTES ||
                (path.length - ADDR_BYTES) % ADDR_UINT16_BYTES != 0;
        }
    }

    /// @dev Assume the path is valid
    function hopCount(bytes memory path) internal pure returns (uint256) {
        unchecked {
            return path.length / ADDR_UINT16_BYTES;
        }
    }

    /// @dev Assume the path is valid
    function decodePool(
        bytes memory path,
        uint256 poolIndex,
        bool exactIn
    )
        internal
        pure
        returns (
            address tokenIn,
            address tokenOut,
            uint256 tierChoices
        )
    {
        unchecked {
            uint256 offset = ADDR_UINT16_BYTES * poolIndex;
            tokenIn = _readAddressAt(path, offset);
            tokenOut = _readAddressAt(path, ADDR_UINT16_BYTES + offset);
            tierChoices = _readUint16At(path, ADDR_BYTES + offset);
            if (!exactIn) (tokenIn, tokenOut) = (tokenOut, tokenIn);
        }
    }

    /// @dev Assume the path is valid
    function tokensInOut(bytes memory path, bool exactIn) internal pure returns (address tokenIn, address tokenOut) {
        unchecked {
            tokenIn = _readAddressAt(path, 0);
            tokenOut = _readAddressAt(path, path.length - ADDR_BYTES);
            if (!exactIn) (tokenIn, tokenOut) = (tokenOut, tokenIn);
        }
    }

    function _readAddressAt(bytes memory data, uint256 offset) internal pure returns (address addr) {
        assembly {
            addr := mload(add(add(data, 20), offset))
        }
    }

    function _readUint16At(bytes memory data, uint256 offset) internal pure returns (uint16 value) {
        assembly {
            value := mload(add(add(data, 2), offset))
        }
    }
}