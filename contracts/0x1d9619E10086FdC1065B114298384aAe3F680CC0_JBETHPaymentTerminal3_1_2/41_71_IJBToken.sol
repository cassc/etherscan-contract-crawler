// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBToken {
  function projectId() external view returns (uint256);

  function decimals() external view returns (uint8);

  function totalSupply(uint256 projectId) external view returns (uint256);

  function balanceOf(address account, uint256 projectId) external view returns (uint256);

  function mint(uint256 projectId, address account, uint256 amount) external;

  function burn(uint256 projectId, address account, uint256 amount) external;

  function approve(uint256, address spender, uint256 amount) external;

  function transfer(uint256 projectId, address to, uint256 amount) external;

  function transferFrom(uint256 projectId, address from, address to, uint256 amount) external;
}