// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

interface IBpool {
  function MAX_BOUND_TOKENS() external view returns (uint256);

  function MAX_WEIGHT() external view returns (uint256);

  function MIN_WEIGHT() external view returns (uint256);

  function execute(
    address _target,
    uint256 _value,
    bytes calldata _data
  ) external returns (bytes memory _returnValue);

  function getBalance(address token) external view returns (uint256);

  function getDenormalizedWeight(address token) external view returns (uint256);

  function getNumTokens() external view returns (uint256);

  function isBound(address t) external view returns (bool);
}