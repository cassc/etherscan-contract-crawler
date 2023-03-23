// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.16;

interface ISpecDataHolder {
  function isSpecRegistered(string memory) external view returns (bool);

  function setSpecToRaft(string memory, uint256) external;

  function getRaftAddress() external view returns (address);

  function getRaftTokenId(string memory) external view returns (uint256);

  function setBadgeToRaft(uint256, uint256) external;

  function isAuthorizedAdmin(uint256 _raftTokenId, address _admin) external view returns (bool);
}