// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;


interface IAsteroidFeatures {

  function getAsteroidSeed(uint _asteroidId) external pure returns (bytes32);

  function getRadius(uint _asteroidId) external pure returns (uint);

  function getSpectralType(uint _asteroidId) external pure returns (uint);

  function getSpectralTypeBySeed(bytes32 _seed) external pure returns (uint);

  function getOrbitalElements(uint _asteroidId) external pure returns (uint[6] memory orbitalElements);

  function getOrbitalElementsBySeed(bytes32 _seed) external pure returns (uint[6] memory orbitalElements);
}