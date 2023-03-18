// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct ProjectConfig {
    uint256 maxAllocations;
    uint256 maxAllocationsPerUser;
    uint256 maxAllocationsPerWhale;
    uint256 maxAllocationsPerNonHolder;
    uint256 totalCollected;
    uint256 endDate;
    address signer;
    bool paused;
    bool openForHolders;
    bool openForWhales;
    bool openForPublic;
}

interface ISpectreAllocations {
  function exists(bytes32 project) external view returns (bool);
  function invested(bytes32 project, address investor) external view returns (uint256);
  function projectConfig(bytes32 project) external view returns (ProjectConfig memory);
}