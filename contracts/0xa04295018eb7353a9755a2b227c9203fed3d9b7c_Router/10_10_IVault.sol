// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

struct Permit {
  uint256 amount;
  uint256 deadline;
  uint8 v;
  bytes32 r;
  bytes32 s;
}

interface IVault {
  function WETH() external view returns (address);

  receive() external payable;

  function deposit() external payable;

  function depositToMPC() external payable;

  function depositTokens(address from, address token, uint256 amount) external;

  function depositTokensToMPC(address from, address token, uint256 amount) external;

  function depositTokensWithPermit(address from, address token, uint256 amount, Permit calldata permit) external;

  function depositTokensToMPCWithPermit(address from, address token, uint256 amount, Permit calldata permit) external;

  function withdraw(address payable to, uint256 amount) external;

  function withdrawTokens(address to, address token, uint256 amount) external;
}