// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 divergence.xyz
pragma solidity >=0.8.8 <0.9.0;

import "./Common.sol";

/// @notice A helper library for `TokenData` serialization.
/// @dev Data is serialized by following the same order and bit-width of fields
/// as given in the definition of the structs using litte-endian encoding.
/// `TokenDataSerialized` will therefore only ever use the rightmost 80 bits.
library Serializer {
    /// @notice Serializes a given set of features.
    function serialize(Features memory features)
        internal
        pure
        returns (FeaturesSerialized)
    {
        unchecked {
            uint48 packed;
            packed += features.background;
            packed <<= 8;
            packed += features.body;
            packed <<= 8;
            packed += features.mouth;
            packed <<= 8;
            packed += features.eyes;
            packed <<= 8;
            packed += uint8(features.special);
            packed <<= 8;
            packed += features.golden ? 1 : 0;
            return FeaturesSerialized.wrap(bytes32(uint256(packed)));
        }
    }

    /// @notice The hash based on which features can be considered to be the
    /// same.
    /// @dev Just a serializaiton and cast
    function hash(Features memory features) internal pure returns (bytes32) {
        return bytes32(FeaturesSerialized.unwrap(serialize(features)));
    }
}

/// @notice A helper library for `TokenDataSerialized` unpacking.
library Deserializer {
    /// @notice Retrieves the `feature` field from serialized data.
    /// @notice Deserializes data into a struct.
    function deserialize(FeaturesSerialized data_)
        internal
        pure
        returns (Features memory)
    {
        unchecked {
            Features memory feats;
            uint256 data = _toUint256(data_);
            feats.golden = uint8(data) == 1;
            data >>= 8;
            feats.special = Special(uint8(data));
            data >>= 8;
            feats.eyes = uint8(data);
            data >>= 8;
            feats.mouth = uint8(data);
            data >>= 8;
            feats.body = uint8(data);
            data >>= 8;
            feats.background = uint8(data);
            return feats;
        }
    }

    /// @notice Checks it the data is set, i.e. non-zero
    function isSet(FeaturesSerialized data) internal pure returns (bool) {
        return FeaturesSerialized.unwrap(data) != 0;
    }

    /// @notice Converts the serialized data to an `uint`.
    function _toUint256(FeaturesSerialized data)
        private
        pure
        returns (uint256)
    {
        return uint256(FeaturesSerialized.unwrap(data));
    }

    /// @notice The hash based on which features can be considered to be the
    /// same.
    /// @dev Just the serialized version
    function hash(FeaturesSerialized features) internal pure returns (bytes32) {
        return FeaturesSerialized.unwrap(features);
    }
}