// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

interface IController {
  function governance() external view returns (address);

  function rewards() external view returns (address);

  function withdraw(address, uint256) external;

  function balanceOf(address) external view returns (uint256);

  function earn(address, uint256) external;

  function want(address) external view returns (address);

  function vaults(address) external view returns (address);

  function strategies(address) external view returns (address);

  function approvedStrategies(address, address) external view returns (bool);

  function converters(address, address) external view returns (address);
}