// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Random {

  /*
  * Compute x[n + 1] = (7^5 * x[n]) mod (2^31 - 1).
  * From "Random number generators: good ones are hard to find",
  * Park and Miller, Communications of the ACM, vol. 31, no. 10,
  * October 1988, p. 1195.
  */
  function prng (uint256 _seed) public pure returns (uint256 seed) {
    seed = (16807 * _seed) % 2147483647;
  }

  function randUInt32 (
    uint256 _seed, 
    uint32 _min, 
    uint32 _max
    ) public pure returns (uint32 rnd) {
      rnd = uint32(_min + _seed % (_max - _min));
  }

   function randBool(
    uint256 _seed, 
    uint32 _threshold
  ) public pure returns (bool rnd) {
    rnd = (_seed % 1000) < _threshold;
  }

  function expRandUInt32(
    uint256 _seed, 
    uint32 _min, 
    uint32 _max
  ) public pure returns (uint32 rnd) {
    uint32 diff = _max - _min; 
    rnd = _min + randUInt32(_seed, 0, diff) * randUInt32(_seed * 7, 0, diff) / diff;
  }
}