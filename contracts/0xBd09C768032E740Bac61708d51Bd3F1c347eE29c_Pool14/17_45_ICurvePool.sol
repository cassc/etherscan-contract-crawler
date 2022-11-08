pragma solidity ^0.8.4;

interface ICurve {
  function exchange_underlying(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy,
    address receiver
  ) external returns (uint256);
}