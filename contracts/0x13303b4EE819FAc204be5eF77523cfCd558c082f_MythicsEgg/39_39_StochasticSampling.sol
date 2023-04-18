// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.15;

import {IEntropyOracle} from "proof/entropy/IEntropyOracle.sol";

/**
 * @notice Helper libray for sampling from a discrete probability distribution.
 */
library StochasticSamplingLib {
    /**
     * @notice Computes the cumulative probability distribution from a discrete probability distribution.
     */
    function computeCDF(uint64[] memory pdf) internal pure returns (uint64[] memory) {
        uint64[] memory cdf = new uint64[](pdf.length);
        cdf[0] = pdf[0];
        for (uint256 i = 1; i < pdf.length; ++i) {
            cdf[i] = cdf[i - 1] + pdf[i];
        }

        return cdf;
    }

    /**
     * @notice Samples from a discrete cumulative probability distribution.
     * @dev This function assumes that rand is uniform in [0,2^256) and that `cdf[cdf.length - 1] << 2^256`. If not the
     * outcome will be biased
     */
    function sampleWithCDF(uint256 rand, uint64[] memory cdf) internal pure returns (uint256) {
        rand = rand % cdf[cdf.length - 1];

        for (uint256 i; i < cdf.length; ++i) {
            if (rand < cdf[i]) {
                return i;
            }
        }

        // This will never be reached given the above bounds of rand.
        assert(false);
        return 0;
    }
}

/**
 * @notice A contract that can sample token traits from discrete probability distributions.
 * @dev The probability distributions and seed derivation functions are implemented in the inheriting contracts.
 * @dev The functions defined here might be gas-heavy and are therefore intended to be used in view-calls only.
 */
abstract contract StochasticSampler {
    /**
     * @notice Returns a random seed for a given token and a boolean indicating whether the seed is available.
     */
    function _seed(uint256 tokenId) internal view virtual returns (bytes32, bool);

    /**
     * @notice Returns the cumulative probability distribution for a given trait of a given token.
     */
    function _cdf(uint256 tokenId, uint256 traitId) internal view virtual returns (uint64[] memory);

    /**
     * @notice Samples a trait for a given token.
     * @dev Returns the sampled trait and a boolean indicating whether the trait was already revealed (i.e. if the seed
     * for the given token is available).
     */
    function _sampleTrait(uint256 tokenId, uint256 traitId) internal view returns (uint256, bool) {
        (bytes32 seed, bool revealed) = _seed(tokenId);
        seed = keccak256(abi.encodePacked(seed, traitId));
        return (StochasticSamplingLib.sampleWithCDF(uint256(seed), _cdf(tokenId, traitId)), revealed);
    }
}

/**
 * @notice A contract that can sample token traits from discrete probability distributions loaded from storage.
 */
abstract contract StochasticSamplerWithCDFStorage is StochasticSampler {
    using StochasticSamplingLib for uint64[];

    /**
     * @notice Thrown if the traitId is invalid, i.e. if it exceeds the number of traits.
     */
    error InvalidTraitId(uint256 traitId);

    /**
     * @notice Thrown if the length of the given PDF does not match the number of realisations in a given trait.
     */
    error IncorrectPDFLength(uint256 gotLength, uint256 traitId, uint256 wantLength);

    /**
     * @notice Thrown if the given PDF cannot be normalised, i.e. if the sum of the probabilities is zero.
     */
    error ConstantZeroPDF();

    /**
     * @notice The number of realisations for each trait.
     */
    uint256[] private _numPerTrait;

    /**
     * @notice The cumulative probability distributions for each trait.
     * @dev Indexed by traitId, distributionVersion, sample.
     * @dev The distributionVersion is intended to allow having multiple "versions" of the probability distributions.
     */
    uint64[][][] private _cdfs;

    constructor(uint256[] memory numPerTrait) {
        _numPerTrait = numPerTrait;
        for (uint256 i; i < numPerTrait.length; ++i) {
            _cdfs.push(new uint64[][](0));
        }
        assert(_cdfs.length == numPerTrait.length);
    }

    /**
     * @notice Adds a new probability distribution for a given trait.
     */
    function _pushProbabilities(uint256 traitId, uint64[] memory pdf) internal {
        if (traitId >= _numPerTrait.length) {
            revert InvalidTraitId(traitId);
        }

        if (pdf.length != _numPerTrait[traitId]) {
            revert IncorrectPDFLength(pdf.length, traitId, _numPerTrait[traitId]);
        }

        uint64[] memory cdf = pdf.computeCDF();
        if (cdf[cdf.length - 1] == 0) {
            revert ConstantZeroPDF();
        }
        _cdfs[traitId].push(cdf);
    }

    /**
     * @notice Returns the version/index of the latest probability distribution for a given trait.
     */
    function _latestDistributionVersion(uint256 traitId) internal view returns (uint256) {
        return _cdfs[traitId].length - 1;
    }

    /**
     * @notice Returns the version/index of the probability distribution that is used for a given token and trait.
     * @dev This function is intended to be overridden by inheriting contracts.
     */
    function _distributionVersion(uint256 tokenId, uint256 traitId) internal view virtual returns (uint256);

    /**
     * @inheritdoc StochasticSampler
     * @dev Returns the probability distribution that is index by `_distributionVersion`.
     */
    function _cdf(uint256 tokenId, uint256 traitId) internal view virtual override returns (uint64[] memory) {
        if (traitId >= _numPerTrait.length) {
            revert InvalidTraitId(traitId);
        }
        return _cdfs[traitId][_distributionVersion(tokenId, traitId)];
    }
}

/**
 * @notice A contract that can sample token traits from discrete probability distributions using entropy provided by the
 * EntropyOracle.
 */
abstract contract StochasticSamplerWithOracle is StochasticSampler {
    /**
     * @notice The entropy oracle.
     */
    IEntropyOracle public entropyOracle;

    constructor(IEntropyOracle entropyOracle_) {
        entropyOracle = entropyOracle_;
    }

    /**
     * @inheritdoc StochasticSampler
     * @dev Uses the entropy of the block at `_revealBlockNumber(tokenId)`.
     */
    function _seed(uint256 tokenId) internal view virtual override returns (bytes32, bool) {
        bytes32 entropy = entropyOracle.blockEntropy(_revealBlockNumber(tokenId));
        return (keccak256(abi.encode(entropy, tokenId)), entropy != 0);
    }

    /**
     * @notice The blocknumber at which a given token will be revealed.
     * @dev The entropy provided by `entropyOracle` for this block will be used as seed for trait sampling.
     */
    function _revealBlockNumber(uint256 tokenId) internal view virtual returns (uint256);
}