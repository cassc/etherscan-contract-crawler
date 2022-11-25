// SPDX-License-Identifier: MIT

/*
 * NounsAssetProvider is a wrapper around NounsDescriptor so that it offers
 * various characters as assets to compose (not individual parts).
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import "randomizer.sol/Randomizer.sol";

interface ILayoutGenerator {
  struct Node {
    uint x;
    uint y;
    uint size;
    string scale;
  }

  function generate(Randomizer.Seed memory _seed, uint _props)
              external view returns(Randomizer.Seed memory seed, Node[] memory nodes);
}