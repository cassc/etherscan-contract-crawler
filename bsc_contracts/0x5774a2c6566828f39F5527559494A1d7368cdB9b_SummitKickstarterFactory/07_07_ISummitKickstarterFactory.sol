// SPDX-License-Identifier: UNLICENSED
// Developed by: dxsoftware.net

pragma solidity 0.8.6;

import "../../structs/KickstarterInfo.sol";

interface ISummitKickstarterFactory {
  function owner() external view returns (address);

  function isAdmin(address _address) external view returns (bool);

  function projects() external view returns (address[] memory);

  function userProjects(address _address) external view returns (address[] memory);

  function serviceFee() external view returns (uint256);

  function createProject(Kickstarter calldata kickstarter) external payable;

  function getProjects() external view returns (address[] memory);

  function getProjectsOf(address _walletAddress) external view returns (address[] memory);

  function setAdmins(address[] calldata _walletAddress, bool _isAdmin) external;

  function withdraw(address _receiver) external;

  function setServiceFee(uint256 _serviceFee) external;
}