// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IMinBetManager {
  function GetMinBet ( address token ) external view returns ( uint256 );
  function IsMinBet ( address token, uint256 amount ) external view returns ( bool );
  function owner (  ) external view returns ( address );
  function renounceOwnership (  ) external;
  function setMinBet ( address token, uint256 minBet ) external;
  function transferOwnership ( address newOwner ) external;
}