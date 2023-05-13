// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

interface IRewardDistributor {
  event RewardClaimed(
    bytes32 indexed identifier,
    address indexed token,
    address indexed account,
    uint256 amount,
    uint256 updateCount
  );
  event RewardMetadataUpdated(
    bytes32 indexed identifier,
    address indexed token,
    bytes32 merkleRoot,
    bytes32 proof,
    uint256 indexed updateCount
  );
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

  function BRIBE_VAULT() external view returns (address);

  function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

  function claim(RewardDistributor.Claim[] memory _claims) external;

  function claimed(bytes32, address) external view returns (uint256);

  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  function grantRole(bytes32 role, address account) external;

  function hasRole(bytes32 role, address account)
  external
  view
  returns (bool);

  function renounceRole(bytes32 role, address account) external;

  function revokeRole(bytes32 role, address account) external;

  function rewards(bytes32)
  external
  view
  returns (
    address token,
    bytes32 merkleRoot,
    bytes32 proof,
    uint256 updateCount
  );

  function supportsInterface(bytes4 interfaceId) external view returns (bool);

  function updateRewardsMetadata(Common.Distribution[] memory _distributions)
  external;
}

interface RewardDistributor {
  struct Claim {
    bytes32 identifier;
    address account;
    uint256 amount;
    bytes32[] merkleProof;
  }
}

interface Common {
  struct Distribution {
    bytes32 identifier;
    address token;
    bytes32 merkleRoot;
    bytes32 proof;
  }
}