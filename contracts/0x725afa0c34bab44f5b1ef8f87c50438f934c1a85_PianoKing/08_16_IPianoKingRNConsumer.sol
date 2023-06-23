// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPianoKingRNConsumer {
  function getRandomNumbers()
    external
    view
    returns (uint256 _randomSeed, uint256 _randomIncrementor);
}