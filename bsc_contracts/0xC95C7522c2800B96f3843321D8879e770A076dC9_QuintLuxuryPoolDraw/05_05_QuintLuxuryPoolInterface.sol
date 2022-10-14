// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface QuintLuxuryPoolInterface {
  function poolEndTime() external view returns (uint256);

  function totalTickets() external view returns (uint256);
}