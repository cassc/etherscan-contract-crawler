// SPDX-License-Identifier: MIT

/**
 * This is a part of an effort to create a decentralized autonomous marketplace for digital assets,
 * which allows artists and developers to sell their arts and generative arts.
 *
 * Please see "https://fullyonchain.xyz/" for details. 
 *
 * Created by Satoshi Nakajima (@snakajima)
 */
pragma solidity ^0.8.6;

import { IAssetProvider } from '../interfaces/IAssetProvider.sol';
import "randomizer.sol/Randomizer.sol";

/**
 * This interface makes it easy to create a new provider from another provider.
 * generateRandomProps geneartes a set of provider-specific properties (packed in 256bits).
 * generatePathWithProps generates a random path using the seed and properties. 
 */
interface IAssetProviderEx is IAssetProvider {
  function generateRandomProps(Randomizer.Seed memory _seed) external pure returns(Randomizer.Seed memory, uint256);
  function generateSVGPartWithProps(Randomizer.Seed memory _seed, uint256 _prop, string memory _tag) external view 
    returns(Randomizer.Seed memory seed, string memory svgPart);
}