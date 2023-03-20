// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

interface IVestable {
  function hasLocked(address _user) external view returns (bool);

  function getLocked(address _user) external view returns (uint256);

  function getVested(address _user) external view returns (uint256);

  function getTotalLocked() external view returns (uint256);

  function lock(uint256 amount) external;

  function unlock(uint256 amount) external;

  function vest() external;

  function vest(address _user) external;

  function convert(uint256 amount) external;
}