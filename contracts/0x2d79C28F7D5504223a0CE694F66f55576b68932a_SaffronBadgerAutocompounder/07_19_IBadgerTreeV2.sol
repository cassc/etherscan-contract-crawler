// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IBadgerTreeV2 {
  event Claimed(
    address indexed user,
    address indexed token,
    uint256 amount,
    uint256 indexed cycle,
    uint256 timestamp,
    uint256 blockNumber
  );
  event InsufficientFundsForRoot(bytes32 indexed root);
  event Paused(address account);
  event RoleAdminChanged(
    bytes32 indexed role,
    bytes32 indexed previousAdminRole,
    bytes32 indexed newAdminRole
  );
  event RoleGranted(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );
  event RoleRevoked(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );
  event RootProposed(
    uint256 indexed cycle,
    bytes32 indexed root,
    bytes32 indexed contentHash,
    uint256 startBlock,
    uint256 endBlock,
    uint256 timestamp,
    uint256 blockNumber
  );
  event RootUpdated(
    uint256 indexed cycle,
    bytes32 indexed root,
    bytes32 indexed contentHash,
    uint256 startBlock,
    uint256 endBlock,
    uint256 timestamp,
    uint256 blockNumber
  );
  event Unpaused(address account);

  function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

  function PAUSER_ROLE() external view returns (bytes32);

  function ROOT_PROPOSER_ROLE() external view returns (bytes32);

  function ROOT_VALIDATOR_ROLE() external view returns (bytes32);

  function UNPAUSER_ROLE() external view returns (bytes32);

  function approveRoot(
    bytes32 root,
    bytes32 contentHash,
    uint256 cycle,
    uint256 startBlock,
    uint256 endBlock
  ) external;

  function claim(
    address[] memory tokens,
    uint256[] memory cumulativeAmounts,
    uint256 index,
    uint256 cycle,
    bytes32[] memory merkleProof,
    uint256[] memory amountsToClaim
  ) external;

  function claimed(address, address) external view returns (uint256);

  function currentCycle() external view returns (uint256);

  function encodeClaim(
    address[] memory tokens,
    uint256[] memory cumulativeAmounts,
    address account,
    uint256 index,
    uint256 cycle
  ) external pure returns (bytes memory encoded, bytes32 hash);

  function getClaimableFor(
    address user,
    address[] memory tokens,
    uint256[] memory cumulativeAmounts
  ) external view returns (address[] memory, uint256[] memory);

  function getClaimedFor(address user, address[] memory tokens)
  external
  view
  returns (address[] memory, uint256[] memory);

  function getCurrentMerkleData()
  external
  view
  returns (BadgerTreeV2.MerkleData memory);

  function getMerkleRootFor(uint256 cycle) external view returns (bytes32);

  function getPendingMerkleData()
  external
  view
  returns (BadgerTreeV2.MerkleData memory);

  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  function getRoleMember(bytes32 role, uint256 index)
  external
  view
  returns (address);

  function getRoleMemberCount(bytes32 role) external view returns (uint256);

  function grantRole(bytes32 role, address account) external;

  function hasPendingRoot() external view returns (bool);

  function hasRole(bytes32 role, address account)
  external
  view
  returns (bool);

  function initialize(
    address admin,
    address initialProposer,
    address initialValidator
  ) external;

  function isClaimAvailableFor(
    address user,
    address[] memory tokens,
    uint256[] memory cumulativeAmounts
  ) external view returns (bool);

  function lastProposeBlockNumber() external view returns (uint256);

  function lastProposeEndBlock() external view returns (uint256);

  function lastProposeStartBlock() external view returns (uint256);

  function lastProposeTimestamp() external view returns (uint256);

  function lastPublishBlockNumber() external view returns (uint256);

  function lastPublishEndBlock() external view returns (uint256);

  function lastPublishStartBlock() external view returns (uint256);

  function lastPublishTimestamp() external view returns (uint256);

  function merkleContentHash() external view returns (bytes32);

  function merkleRoot() external view returns (bytes32);

  function pause() external;

  function paused() external view returns (bool);

  function pendingCycle() external view returns (uint256);

  function pendingMerkleContentHash() external view returns (bytes32);

  function pendingMerkleRoot() external view returns (bytes32);

  function proposeRoot(
    bytes32 root,
    bytes32 contentHash,
    uint256 cycle,
    uint256 startBlock,
    uint256 endBlock
  ) external;

  function renounceRole(bytes32 role, address account) external;

  function revokeRole(bytes32 role, address account) external;

  function setCycle(uint256 x) external;

  function totalClaimed(address) external view returns (uint256);

  function unpause() external;
}

interface BadgerTreeV2 {
  struct MerkleData {
    bytes32 root;
    bytes32 contentHash;
    uint256 timestamp;
    uint256 publishBlock;
    uint256 startBlock;
    uint256 endBlock;
  }
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"user","type":"address"},{"indexed":true,"internalType":"address","name":"token","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":true,"internalType":"uint256","name":"cycle","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"timestamp","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"blockNumber","type":"uint256"}],"name":"Claimed","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"root","type":"bytes32"}],"name":"InsufficientFundsForRoot","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"account","type":"address"}],"name":"Paused","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"role","type":"bytes32"},{"indexed":true,"internalType":"bytes32","name":"previousAdminRole","type":"bytes32"},{"indexed":true,"internalType":"bytes32","name":"newAdminRole","type":"bytes32"}],"name":"RoleAdminChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"role","type":"bytes32"},{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":true,"internalType":"address","name":"sender","type":"address"}],"name":"RoleGranted","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"role","type":"bytes32"},{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":true,"internalType":"address","name":"sender","type":"address"}],"name":"RoleRevoked","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"cycle","type":"uint256"},{"indexed":true,"internalType":"bytes32","name":"root","type":"bytes32"},{"indexed":true,"internalType":"bytes32","name":"contentHash","type":"bytes32"},{"indexed":false,"internalType":"uint256","name":"startBlock","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"endBlock","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"timestamp","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"blockNumber","type":"uint256"}],"name":"RootProposed","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"cycle","type":"uint256"},{"indexed":true,"internalType":"bytes32","name":"root","type":"bytes32"},{"indexed":true,"internalType":"bytes32","name":"contentHash","type":"bytes32"},{"indexed":false,"internalType":"uint256","name":"startBlock","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"endBlock","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"timestamp","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"blockNumber","type":"uint256"}],"name":"RootUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"account","type":"address"}],"name":"Unpaused","type":"event"},{"inputs":[],"name":"DEFAULT_ADMIN_ROLE","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"PAUSER_ROLE","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"ROOT_PROPOSER_ROLE","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"ROOT_VALIDATOR_ROLE","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"UNPAUSER_ROLE","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"root","type":"bytes32"},{"internalType":"bytes32","name":"contentHash","type":"bytes32"},{"internalType":"uint256","name":"cycle","type":"uint256"},{"internalType":"uint256","name":"startBlock","type":"uint256"},{"internalType":"uint256","name":"endBlock","type":"uint256"}],"name":"approveRoot","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address[]","name":"tokens","type":"address[]"},{"internalType":"uint256[]","name":"cumulativeAmounts","type":"uint256[]"},{"internalType":"uint256","name":"index","type":"uint256"},{"internalType":"uint256","name":"cycle","type":"uint256"},{"internalType":"bytes32[]","name":"merkleProof","type":"bytes32[]"},{"internalType":"uint256[]","name":"amountsToClaim","type":"uint256[]"}],"name":"claim","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"}],"name":"claimed","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"currentCycle","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"tokens","type":"address[]"},{"internalType":"uint256[]","name":"cumulativeAmounts","type":"uint256[]"},{"internalType":"address","name":"account","type":"address"},{"internalType":"uint256","name":"index","type":"uint256"},{"internalType":"uint256","name":"cycle","type":"uint256"}],"name":"encodeClaim","outputs":[{"internalType":"bytes","name":"encoded","type":"bytes"},{"internalType":"bytes32","name":"hash","type":"bytes32"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"address","name":"user","type":"address"},{"internalType":"address[]","name":"tokens","type":"address[]"},{"internalType":"uint256[]","name":"cumulativeAmounts","type":"uint256[]"}],"name":"getClaimableFor","outputs":[{"internalType":"address[]","name":"","type":"address[]"},{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"user","type":"address"},{"internalType":"address[]","name":"tokens","type":"address[]"}],"name":"getClaimedFor","outputs":[{"internalType":"address[]","name":"","type":"address[]"},{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getCurrentMerkleData","outputs":[{"components":[{"internalType":"bytes32","name":"root","type":"bytes32"},{"internalType":"bytes32","name":"contentHash","type":"bytes32"},{"internalType":"uint256","name":"timestamp","type":"uint256"},{"internalType":"uint256","name":"publishBlock","type":"uint256"},{"internalType":"uint256","name":"startBlock","type":"uint256"},{"internalType":"uint256","name":"endBlock","type":"uint256"}],"internalType":"struct BadgerTreeV2.MerkleData","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"cycle","type":"uint256"}],"name":"getMerkleRootFor","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getPendingMerkleData","outputs":[{"components":[{"internalType":"bytes32","name":"root","type":"bytes32"},{"internalType":"bytes32","name":"contentHash","type":"bytes32"},{"internalType":"uint256","name":"timestamp","type":"uint256"},{"internalType":"uint256","name":"publishBlock","type":"uint256"},{"internalType":"uint256","name":"startBlock","type":"uint256"},{"internalType":"uint256","name":"endBlock","type":"uint256"}],"internalType":"struct BadgerTreeV2.MerkleData","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"}],"name":"getRoleAdmin","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"},{"internalType":"uint256","name":"index","type":"uint256"}],"name":"getRoleMember","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"}],"name":"getRoleMemberCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"},{"internalType":"address","name":"account","type":"address"}],"name":"grantRole","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"hasPendingRoot","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"},{"internalType":"address","name":"account","type":"address"}],"name":"hasRole","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"admin","type":"address"},{"internalType":"address","name":"initialProposer","type":"address"},{"internalType":"address","name":"initialValidator","type":"address"}],"name":"initialize","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"user","type":"address"},{"internalType":"address[]","name":"tokens","type":"address[]"},{"internalType":"uint256[]","name":"cumulativeAmounts","type":"uint256[]"}],"name":"isClaimAvailableFor","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lastProposeBlockNumber","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lastProposeEndBlock","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lastProposeStartBlock","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lastProposeTimestamp","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lastPublishBlockNumber","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lastPublishEndBlock","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lastPublishStartBlock","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lastPublishTimestamp","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"merkleContentHash","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"merkleRoot","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"paused","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pendingCycle","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pendingMerkleContentHash","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pendingMerkleRoot","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"root","type":"bytes32"},{"internalType":"bytes32","name":"contentHash","type":"bytes32"},{"internalType":"uint256","name":"cycle","type":"uint256"},{"internalType":"uint256","name":"startBlock","type":"uint256"},{"internalType":"uint256","name":"endBlock","type":"uint256"}],"name":"proposeRoot","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"},{"internalType":"address","name":"account","type":"address"}],"name":"renounceRole","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"},{"internalType":"address","name":"account","type":"address"}],"name":"revokeRole","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"x","type":"uint256"}],"name":"setCycle","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"totalClaimed","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"unpause","outputs":[],"stateMutability":"nonpayable","type":"function"}]
*/