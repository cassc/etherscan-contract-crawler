// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
// GENERATED CODE - DO NOT EDIT
pragma solidity 0.8.16;

/**
 * @notice Struct that unambiguously defines the artwork and attributes of a
 * token.
 */
struct Features {
    /// @dev Valid range [0, 11)
    uint8 background;
    /// @dev Valid range [0, 20)
    uint8 beak;
    /// @dev Valid range [0, 113)
    uint8 body;
    /// @dev Valid range [0, 63)
    uint8 eyes;
    /// @dev Valid range [0, 13)
    uint8 eyewear;
    /// @dev Valid range [0, 38)
    uint8 headwear;
    /// @dev Valid range [0, 9)
    uint8 outerwear;
}

/**
 * @notice Enumeration of the fields in the `Features` struct.
 */
enum FeatureType {
    Background,
    Beak,
    Body,
    Eyes,
    Eyewear,
    Headwear,
    Outerwear
}

/**
 * @notice Utility library to work with `Features`
 * @dev This library assumes that `Features` contain <=256 bit of information
 * for efficiency.
 */
library FeaturesLib {
    /**
     * @notice Thrown if the feature validation fails.
     */
    error InvalidFeatures(FeatureType, uint256);

    /**
     * @notice Thrown if a deserialisation from bytes with invalid lenght is
     * attempted.
     */
    error InvalidLength();

    /**
     * @notice The Merkle root of all features
     */
    bytes32 public constant FEATURES_ROOT = hex"f8b43e6d091349677b52df00d4dbec8ac3a71d9a48df3eeece013f20733e8355";

    /**
     * @notice Total number of tokens
     */
    uint16 public constant NUM_TOKENS = 10000;

    /**
     * @notice Number of bytes in the features struct.
     */
    uint8 public constant FEATURES_LENGTH = 7;

    /**
     *  @notice Reverts if the given features are invalid.
     */
    function validate(Features memory features) internal pure {
        if (features.background >= 11) {
            revert InvalidFeatures(FeatureType.Background, features.background);
        }
        if (features.beak >= 20) {
            revert InvalidFeatures(FeatureType.Beak, features.beak);
        }
        if (features.body >= 113) {
            revert InvalidFeatures(FeatureType.Body, features.body);
        }
        if (features.eyes >= 63) {
            revert InvalidFeatures(FeatureType.Eyes, features.eyes);
        }
        if (features.eyewear >= 13) {
            revert InvalidFeatures(FeatureType.Eyewear, features.eyewear);
        }
        if (features.headwear >= 38) {
            revert InvalidFeatures(FeatureType.Headwear, features.headwear);
        }
        if (features.outerwear >= 9) {
            revert InvalidFeatures(FeatureType.Outerwear, features.outerwear);
        }
    }

    /**
     * @notice Serialises given features.
     */
    function serialise(Features memory features) internal pure returns (uint256) {
        uint256 ret;

        ret |= uint256(features.background);
        ret <<= 8;
        ret |= uint256(features.beak);
        ret <<= 8;
        ret |= uint256(features.body);
        ret <<= 8;
        ret |= uint256(features.eyes);
        ret <<= 8;
        ret |= uint256(features.eyewear);
        ret <<= 8;
        ret |= uint256(features.headwear);
        ret <<= 8;
        ret |= uint256(features.outerwear);
        return ret;
    }

    /**
     * @notice Computes the hash of given a feature set together with its
     * tokenId.
     * @dev Used for merkle proofs.
     */
    function hash(Features memory features, uint256 tokenId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenId, serialise(features)));
    }

    /**
     * @notice Deserialise features from an unit256.
     */
    function deserialise(uint256 data) internal pure returns (Features memory features) {
        features.outerwear = uint8(data);
        data >>= 8;
        features.headwear = uint8(data);
        data >>= 8;
        features.eyewear = uint8(data);
        data >>= 8;
        features.eyes = uint8(data);
        data >>= 8;
        features.body = uint8(data);
        data >>= 8;
        features.beak = uint8(data);
        data >>= 8;
        features.background = uint8(data);
    }

    /**
     * @notice Deserialise features from a bytes array.
     * @dev Used to deserialise bucket data.
     */
    function deserialise(bytes memory data) internal pure returns (Features memory) {
        if (data.length != 7) {
            revert InvalidLength();
        }

        uint256 data_;
        assembly {
            data_ := shr(200, mload(add(data, 0x20)))
        }

        return deserialise(data_);
    }
}