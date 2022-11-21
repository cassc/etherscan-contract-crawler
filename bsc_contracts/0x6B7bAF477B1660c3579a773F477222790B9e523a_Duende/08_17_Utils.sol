// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Utils {
  function randomSeed(uint256 seed) internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), block.difficulty, seed)));
  }

  /// Random [0, modulus)
  function random(uint256 seed, uint256 modulus) internal view returns (uint256 nextSeed, uint256 result) {
    nextSeed = randomSeed(seed);
    result = nextSeed % modulus;
  }

  /// Random [from, to)
  function randomRange(
    uint256 seed,
    uint256 from,
    uint256 to
  ) internal view returns (uint256 nextSeed, uint256 result) {
    require(from < to, "Invalid random range");
    (nextSeed, result) = random(seed, to - from);
    result += from;
  }

  /// Random [from, to]
  function randomRangeInclusive(
    uint256 seed,
    uint256 from,
    uint256 to
  ) internal view returns (uint256 nextSeed, uint256 result) {
    return randomRange(seed, from, to + 1);
  }

  /// Weighted random.
  function weightedRandom(uint256 seed, uint256[] memory weights)
    internal
    view
    returns (uint256 nextSeed, uint256 index)
  {
    require(weights.length > 0, "Array must not empty");
    uint256 totalWeight;
    for (uint256 i = 0; i < weights.length; ++i) {
      totalWeight += weights[i];
    }
    uint256 randMod;
    (seed, randMod) = randomRange(seed, 0, totalWeight);
    uint256 total;
    for (uint256 i = 0; i < weights.length; i++) {
      total += weights[i];
      if (randMod < total) {
        return (seed, i);
      }
    }
    return (seed, 0);
  }

  /// Reservoir sampling.
  function randomSampling(
    uint256 seed,
    uint256[] storage arr,
    uint256 size
  ) internal view returns (uint256 nextSeed, uint256[] memory result) {
    require(arr.length >= size, "Invalid sampling size");
    result = new uint256[](size);
    for (uint256 i = 0; i < size; ++i) {
      result[i] = arr[i];
    }
    uint256 j;
    for (uint256 i = size; i < arr.length; ++i) {
      (seed, j) = randomRangeInclusive(seed, 0, i);
      if (j < size) {
        result[j] = arr[i];
      }
    }
    nextSeed = seed;
  }

  function weightedRandomSampling(
    uint256 seed,
    uint256[] storage arr,
    uint256[] memory weights,
    uint256 size
  ) internal view returns (uint256 nextSeed, uint256[] memory result) {
    require(arr.length >= size, "Invalid sampling size");
    result = new uint256[](size);
    uint256 index;
    for (uint256 i = 0; i < size; ++i) {
      (seed, index) = weightedRandom(seed, weights);
      weights[index] = 0;
      result[i] = arr[index];
    }
    nextSeed = seed;
  }
}