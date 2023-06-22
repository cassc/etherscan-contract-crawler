// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

interface IHegicPoolV3Depositable {
  event Deposited(
    address depositor, 
    uint256 tokenAmount, 
    uint256 depositorShares,
    uint256 poolShares,
    uint256 protocolShares
  );
  function deposit(uint256 amount) external returns (uint256 shares);
  function depositAll() external returns (uint256 shares);
}