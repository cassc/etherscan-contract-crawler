// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBank {

  function TAX() external view returns (uint256);

  function DIVIDER() external view returns (uint256);

  function token() external view returns (address);

  function reserveTreasury() external view returns (address);

  function totalInterestClaimed() external view returns (uint256);

  function totalReserve() external view returns (uint256);

  function invest(uint256) external;

  function sell(uint256) external;

  function claimInterest() external;

  function totalClaimRequired() external view returns (uint256);

  function claimRequired(uint256) external view returns (uint256);

  function totalContributed() external view returns (uint256);

  function getInterest() external view returns (uint256);

  function getTotalSupply() external view returns (uint256);

  function getBurnedTokensAmount() external view returns (uint256);

  function getCurrentTokenPrice() external view returns (uint256);

  function getReserveToTokensTaxed(uint256) external view returns (uint256);

  function getTokensToReserveTaxed(uint256) external view returns (uint256);

  function getReserveToTokens(uint256) external view returns (uint256);

  function getTokensToReserve(uint256) external view returns (uint256);
}