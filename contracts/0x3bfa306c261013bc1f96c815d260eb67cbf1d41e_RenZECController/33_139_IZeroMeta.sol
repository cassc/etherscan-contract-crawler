pragma solidity >=0.6.0;

interface IZeroMeta {
  function receiveMeta(
    address from,
    address asset,
    uint256 nonce,
    bytes memory data
  ) external;

  function repayMeta(uint256 value) external;
}