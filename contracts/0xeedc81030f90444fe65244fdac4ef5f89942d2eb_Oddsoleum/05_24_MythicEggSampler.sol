// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.15;

import {IEntropyOracle} from "proof/entropy/IEntropyOracle.sol";

import {MythicsEggErrors} from "./MythicsEggErrors.sol";
import {
    StochasticSampler, StochasticSamplerWithCDFStorage, StochasticSamplerWithOracle
} from "./StochasticSampling.sol";

/**
 * @title Mythics: Egg type sampling module
 * @author David Huber (@cxkoda)
 * @custom:reviewer Arran Schlosberg (@divergencearran)
 */
abstract contract MythicEggSampler is StochasticSamplerWithCDFStorage, StochasticSamplerWithOracle, MythicsEggErrors {
    /**
     * @notice The different types of eggs.
     */
    enum EggType {
        Stone,
        Runic,
        Legendary
    }

    /**
     * @notice Number of egg types
     */
    uint8 public constant NUM_EGG_TYPES = 3;

    /**
     * @notice Trait ID for the egg type
     */
    uint8 private constant _EGG_TYPE_TRAIT_ID = 0;

    /**
     * @notice Token-specific parameters for sampling the egg type
     * @dev Will be determined at mint.
     * @param revealBlockNumber Number of the block whose entropy will be used to reaveal the egg type.
     * @param distributionVersion The version/index of probability distribution to sample the egg type.
     * @param mixHash Part of the block mixHash to blind the entropy oracle.
     */
    struct SamplingParams {
        uint64 revealBlockNumber;
        uint16 distributionVersion;
        uint128 mixHash;
    }

    /**
     * @notice Egg-type sampling parameters keyed by token ID.
     */
    mapping(uint256 => SamplingParams) private _samplingParams;

    /**
     * @dev Constructor helper function.
     */
    function _numPerTrait() private pure returns (uint256[] memory) {
        uint256[] memory numPerTrait = new uint256[](1);
        numPerTrait[_EGG_TYPE_TRAIT_ID] = NUM_EGG_TYPES;
        return numPerTrait;
    }

    constructor(IEntropyOracle oracle)
        StochasticSamplerWithCDFStorage(_numPerTrait())
        StochasticSamplerWithOracle(oracle)
    {}

    /**
     * @notice Returns the egg-type sampling parameters for a given token ID.
     */
    function samplingParams(uint256 tokenId) public view returns (SamplingParams memory) {
        if (!_exists(tokenId)) {
            revert NonexistentEgg(tokenId);
        }

        return _samplingParams[tokenId];
    }

    /**
     * @inheritdoc StochasticSamplerWithCDFStorage
     * @dev Reads the token-specific parameters.
     */
    function _distributionVersion(uint256 tokenId, uint256 traitId) internal view virtual override returns (uint256) {
        assert(traitId == _EGG_TYPE_TRAIT_ID);
        return _samplingParams[tokenId].distributionVersion;
    }

    /**
     * @inheritdoc StochasticSamplerWithOracle
     * @dev Reads the token-specific parameters.
     */
    function _revealBlockNumber(uint256 tokenId) internal view virtual override returns (uint256) {
        return _samplingParams[tokenId].revealBlockNumber;
    }

    /**
     * @notice Registers a token for egg-type sampling using the currently set probability distribution.
     * @dev Must be called upon token mint.
     */
    function _registerForSampling(uint256 tokenId) internal {
        uint256 revealBlockNumber = block.number;

        _samplingParams[tokenId] = SamplingParams({
            revealBlockNumber: uint64(revealBlockNumber),
            distributionVersion: uint16(_latestDistributionVersion(_EGG_TYPE_TRAIT_ID)),
            // Smearing out single-bit-of-influence from the prevrandao since we're just using 128 bits (mainly to
            // prevent the forge fuzzer from finding breaking runs which would force us to add circular testing logic).
            mixHash: uint128(uint256(keccak256(abi.encode(block.prevrandao))))
        });
        entropyOracle.requestEntropy(revealBlockNumber);
    }

    /**
     * @notice Sets the probability distribution for egg types.
     */
    function _setEggProbabilities(uint64[NUM_EGG_TYPES] memory pdf) internal {
        uint64[] memory p = new uint64[](NUM_EGG_TYPES);
        for (uint256 i = 0; i < NUM_EGG_TYPES; i++) {
            p[i] = pdf[i];
        }
        _pushProbabilities(_EGG_TYPE_TRAIT_ID, p);
    }

    /**
     * @inheritdoc StochasticSamplerWithOracle
     * @dev Mixes the seed with the token-specific parameters to blind the EntropyOracle.
     */
    function _seed(uint256 tokenId)
        internal
        view
        virtual
        override(StochasticSampler, StochasticSamplerWithOracle)
        returns (bytes32, bool)
    {
        (bytes32 seed, bool revealed) = StochasticSamplerWithOracle._seed(tokenId);
        return (keccak256(abi.encode(seed, samplingParams(tokenId))), revealed);
    }

    /**
     * @notice Returns the egg type of a given token ID and a boolean flag to indicate whether it was already revealed.
     */
    function eggType(uint256 tokenId) public view returns (EggType, bool) {
        (uint256 sample, bool revealed) = _sampleTrait(tokenId, _EGG_TYPE_TRAIT_ID);
        return (EggType(sample), revealed);
    }

    /**
     * @notice Returns whether a token exists.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool);
}