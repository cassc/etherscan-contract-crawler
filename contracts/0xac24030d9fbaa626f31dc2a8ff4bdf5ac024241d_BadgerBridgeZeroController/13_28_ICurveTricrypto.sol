pragma solidity >=0.6.0 <0.8.0;

interface ICurveTricrypto {
  function exchange(
    uint256 i,
    uint256 j,
    uint256 dx,
    uint256 min_dy,
    bool use_eth
  ) external payable;
}