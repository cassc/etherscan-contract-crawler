// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
interface BAPGenesisInterface {
  function mintingDatetime(uint256) external view returns (uint256);
  function tokenExist(uint256) external view returns (bool);
  function ownerOf(uint256) external view returns (address);
  function dailyRewards(bool) external view returns (uint256);
  function initialMintingTimestamp() external view returns (uint256);
  function originalMintingPrice(uint256) external view returns (uint256);
  function breedings(uint256) external view returns (uint256);
  function maxBreedings() external view returns (uint256);
  function breedBulls(uint256,uint256) external;
  function _orchestrator() external view returns (address);
  function approve(address, uint256) external;
  function refund(address, uint256) external payable;
  function safeTransferFrom(address,address,uint256) external;
  function refundPeriodAllowed(uint256) external view returns(bool);
  function notAvailableForRefund(uint256) external returns(bool);
  function generateGodBull() external;
  function genesisTimestamp() external view returns(uint256);
  function setGrazingPeriodTime(uint256) external;
  function setTimeCounter(uint256) external; 
  function secret() external view returns(address);
  function minted() external view returns(uint256);
  function updateBullBreedings(uint256) external;
}