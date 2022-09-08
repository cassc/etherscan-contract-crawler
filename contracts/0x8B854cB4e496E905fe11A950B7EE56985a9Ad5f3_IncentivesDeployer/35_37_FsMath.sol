//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

/// @title Utility methods basic math operations.
///      NOTE In order for the fuzzing tests to be isolated, all functions in this library need to
///      be `internal`.  Otherwise a contract that uses this library has a dependency on the
///      library.
///
///      Our current Echidna setup requires contracts to be deployable in isolation, so make sure to
///      keep the functions `internal`, until we update our Echidna tests to support more complex
///      setups.
library FsMath {
    uint256 constant BITS_108 = (1 << 108) - 1;
    int256 constant BITS_108_MIN = -(1 << 107);
    uint256 constant BITS_108_MASKED = ~BITS_108;
    uint256 constant BITS_108_SIGN = 1 << 107;
    int256 constant FIXED_POINT_BASED = 1 ether;

    function abs(int256 value) internal pure returns (uint256) {
        if (value >= 0) {
            // slither-disable-next-line safe-cast
            return uint256(value);
        }
        // slither-disable-next-line safe-cast
        return uint256(-value);
    }

    function sabs(int256 value) internal pure returns (int256) {
        if (value >= 0) {
            return value;
        }
        return -value;
    }

    function sign(int256 value) internal pure returns (int256) {
        if (value < 0) {
            return -1;
        } else if (value > 0) {
            return 1;
        } else {
            return 0;
        }
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    // Clip val into interval [lower, upper]
    function clip(
        int256 val,
        int256 lower,
        int256 upper
    ) internal pure returns (int256) {
        return min(max(val, lower), upper);
    }

    function safeCastToSigned(uint256 x) internal pure returns (int256) {
        // slither-disable-next-line safe-cast
        int256 ret = int256(x);
        require(ret >= 0, "Cast overflow");
        return ret;
    }

    function safeCastToUnsigned(int256 x) internal pure returns (uint256) {
        require(x >= 0, "Cast underflow");
        // slither-disable-next-line safe-cast
        return uint256(x);
    }

    /// @notice Encode a int256 into a string hex value prepended with a magic identifier "stable0x"
    function encodeValue(int256 value) external pure returns (string memory) {
        return encodeValueStatic(value);
    }

    /// @notice Encode a int256 into a string hex value prepended with a magic identifier "stable0x"
    ///
    /// @dev This is a "static" version of `encodeValue`.  A contract using this method will not
    ///      have a dependency on the library.
    function encodeValueStatic(int256 value) internal pure returns (string memory) {
        // We are going to encode the two's complement representation.  To be consumed
        // by`decodeValue()`.
        // slither-disable-next-line safe-cast
        bytes32 y = bytes32(uint256(value));
        bytes memory bytesArray = new bytes(8 + 64);
        bytesArray[0] = "s";
        bytesArray[1] = "t";
        bytesArray[2] = "a";
        bytesArray[3] = "b";
        bytesArray[4] = "l";
        bytesArray[5] = "e";
        bytesArray[6] = "0";
        bytesArray[7] = "x";
        for (uint256 i = 0; i < 32; i++) {
            // slither-disable-next-line safe-cast
            uint8 x = uint8(y[i]);
            uint8 u = x >> 4;
            uint8 l = x & 0xF;
            bytesArray[8 + 2 * i] = u >= 10 ? bytes1(u + 65 - 10) : bytes1(u + 48);
            bytesArray[8 + 2 * i + 1] = l >= 10 ? bytes1(l + 65 - 10) : bytes1(l + 48);
        }
        // Bytes we generated above are valid UTF-8.
        // slither-disable-next-line safe-cast
        return string(bytesArray);
    }

    /// @notice Decode an encoded int256 value above.
    /// @return 0 if string is not of the right format.
    function decodeValue(bytes memory r) external pure returns (int256) {
        return decodeValueStatic(r);
    }

    /// @notice Decode an encoded int256 value above.
    /// @dev This is a "static" version of `encodeValue`.  A contract using this method will not
    ///      have a dependency on the library.
    /// @return 0 if string is not of the right format.
    function decodeValueStatic(bytes memory r) internal pure returns (int256) {
        if (
            r.length == 8 + 64 &&
            r[0] == "s" &&
            r[1] == "t" &&
            r[2] == "a" &&
            r[3] == "b" &&
            r[4] == "l" &&
            r[5] == "e" &&
            r[6] == "0" &&
            r[7] == "x"
        ) {
            uint256 y;
            for (uint256 i = 0; i < 64; i++) {
                // slither-disable-next-line safe-cast
                uint8 h = uint8(r[8 + i]);
                uint256 x;
                if (h >= 65) {
                    if (h >= 65 + 16) return 0;
                    x = (h + 10) - 65;
                } else {
                    if (!(h >= 48 && h < 48 + 10)) return 0;
                    x = h - 48;
                }
                y |= x << (256 - 4 - 4 * i);
            }
            // We were decoding a two's complement representation.  Produced by `encodeValue()`.
            // slither-disable-next-line safe-cast
            return int256(y);
        } else {
            return 0;
        }
    }

    /// @notice Returns the lower 108 bits of data as a positive int256
    function read108(uint256 data) internal pure returns (int256) {
        // slither-disable-next-line safe-cast
        return int256(data & BITS_108);
    }

    /// @notice Returns the lower 108 bits sign extended as a int256
    function readSigned108(uint256 data) internal pure returns (int256) {
        uint256 temp = data & BITS_108;

        if (temp & BITS_108_SIGN > 0) {
            temp = temp | BITS_108_MASKED;
        }
        // slither-disable-next-line safe-cast
        return int256(temp);
    }

    /// @notice Performs a range check and returns the lower 108 bits of the value
    function pack108(int256 value) internal pure returns (uint256) {
        if (value >= 0) {
            // slither-disable-next-line safe-cast
            require(value <= int256(BITS_108), "RE");
        } else {
            require(value >= BITS_108_MIN, "RE");
        }

        // Ranges were checked above.  And we expect negative values to be encoded in a two's
        // complement form, as this is how we decode them in `readSigned108()`.
        // slither-disable-next-line safe-cast
        return uint256(value) & BITS_108;
    }

    /// @notice Calculate the leverage amount given amounts of stable/asset and the asset price.
    function calculateLeverage(
        int256 assetAmount,
        int256 stableAmount,
        int256 assetPrice
    ) internal pure returns (uint256) {
        // Return early for gas saving.
        if (assetAmount == 0) {
            return 0;
        }
        int256 assetInStable = assetToStable(assetAmount, assetPrice);
        int256 collateral = assetInStable + stableAmount;
        // Avoid division by 0.
        require(collateral > 0, "Insufficient collateral");
        // slither-disable-next-line safe-cast
        return FsMath.abs(assetInStable * FIXED_POINT_BASED) / uint256(collateral);
    }

    /// @notice Returns the worth of the given asset amount in stable token.
    function assetToStable(int256 assetAmount, int256 assetPrice) internal pure returns (int256) {
        return (assetAmount * assetPrice) / FIXED_POINT_BASED;
    }

    /// @notice Returns the worth of the given stable amount in asset token.
    function stableToAsset(int256 stableAmount, int256 assetPrice) internal pure returns (int256) {
        return (stableAmount * FIXED_POINT_BASED) / assetPrice;
    }
}