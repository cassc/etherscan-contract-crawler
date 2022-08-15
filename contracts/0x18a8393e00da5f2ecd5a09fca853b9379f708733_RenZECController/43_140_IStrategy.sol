// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface StrategyAPI {
  function name() external view returns (string memory);

  function vault() external view returns (address);

  function nativeWrapper() external view returns (address);

  function want() external view returns (address);

  function vaultWant() external view returns (address);

  function apiVersion() external pure returns (string memory);

  function keeper() external view returns (address);

  function isActive() external view returns (bool);

  function delegatedAssets() external view returns (uint256);

  function estimatedTotalAssets() external view returns (uint256);

  function tendTrigger(uint256 callCost) external view returns (bool);

  function tend() external;

  function harvestTrigger(uint256 callCost) external view returns (bool);

  function harvest() external;

  event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);
}

abstract contract IStrategy is StrategyAPI {
  function permissionedSend(address _module, uint256 _amount) external virtual returns (uint256);

  function withdrawAll() external virtual;

  function deposit() external virtual;

  function balanceOf() external view virtual returns (uint256);

  function withdraw(uint256) external virtual;

  function withdraw(address) external virtual;

  function permissionedEther(address, uint256) external virtual;
}