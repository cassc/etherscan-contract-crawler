// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <0.8.0;

interface IFujiAdmin {
  function getFlasher() external view returns (address);

  function getFliquidator() external view returns (address);

  function getController() external view returns (address);

  function getTreasury() external view returns (address payable);

  function getaWhiteList() external view returns (address);

  function getVaultHarvester() external view returns (address);

  function getBonusFlashL() external view returns (uint64, uint64);

  function getBonusLiq() external view returns (uint64, uint64);
}