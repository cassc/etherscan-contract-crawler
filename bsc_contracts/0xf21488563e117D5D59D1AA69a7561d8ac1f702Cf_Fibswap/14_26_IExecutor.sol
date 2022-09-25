// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

interface IExecutor {
  event Executed(
    bytes32 indexed transferId,
    address indexed to,
    address recovery,
    address assetId,
    uint256 amount,
    bytes callData,
    bool success
  );

  function getFibswap() external returns (address);

  function execute(
    bytes32 _transferId,
    uint256 _amount,
    address payable _to,
    address payable _recovery,
    address _assetId,
    bytes calldata _callData
  ) external returns (bool success);
}