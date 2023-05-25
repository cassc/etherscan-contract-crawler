// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface ISequencer {
  struct WorkableJob {
    address job;
    bool canWork;
    bytes args;
  }

  event Rely(address indexed usr);
  event Deny(address indexed usr);
  event File(bytes32 indexed what, uint256 data);
  event AddNetwork(bytes32 indexed network);
  event RemoveNetwork(bytes32 indexed network);
  event AddJob(address indexed job);
  event RemoveJob(address indexed job);

  error InvalidFileParam(bytes32 what);
  error NetworkExists(bytes32 network);
  error NetworkDoesNotExist(bytes32 network);
  error JobExists(address job);
  error JobDoesNotExist(address network);
  error IndexTooHigh(uint256 index, uint256 length);
  error BadIndicies(uint256 startIndex, uint256 exclEndIndex);

  function wards(address) external returns (uint256);

  function rely(address usr) external;

  function deny(address usr) external;

  function window() external returns (uint256);

  function file(bytes32 what, uint256 data) external;

  function addNetwork(bytes32 network) external;

  function removeNetwork(uint256 index) external;

  function addJob(address job) external;

  function removeJob(uint256 index) external;

  function isMaster(bytes32 _network) external view returns (bool _isMaster);

  function numNetworks() external view returns (uint256);

  function hasNetwork() external view returns (bool);

  function networkAt(uint256 index) external view returns (bytes32);

  function numJobs() external view returns (uint256);

  function hasJob(address job) external returns (bool);

  function jobAt(uint256 index) external view returns (address);

  function getNextJobs(
    bytes32 network,
    uint256 startIndex,
    uint256 endIndexExcl
  ) external returns (WorkableJob[] memory);

  function getNextJobs(bytes32 network) external returns (WorkableJob[] memory);
}