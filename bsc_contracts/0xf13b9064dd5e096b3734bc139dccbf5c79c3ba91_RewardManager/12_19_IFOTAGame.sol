// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

interface IFOTAGame {
  function validateInviter(address _inviter) external view returns (bool);
  function getTotalWinInDay(address _user) external view returns (uint);
  function getTotalPVEWinInDay(address _user) external view returns (uint);
  function getTotalPVPWinInDay(address _user) external view returns (uint);
  function getTotalDUALWinInDay(address _user) external view returns (uint);
  function updateLandLord(uint _mission, address _landLord) external;
}