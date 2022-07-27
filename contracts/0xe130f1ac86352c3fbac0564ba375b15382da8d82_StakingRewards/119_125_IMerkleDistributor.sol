// SPDX-License-Identifier: GPL-3.0-only
// solhint-disable-next-line max-line-length
// Adapted from https://github.com/Uniswap/merkle-distributor/blob/c3255bfa2b684594ecd562cacd7664b0f18330bf/contracts/interfaces/IMerkleDistributor.sol.
pragma solidity 0.6.12;

/// @notice Enables the granting of a CommunityRewards grant, if the grant details exist in this
/// contract's Merkle root.
interface IMerkleDistributor {
  /// @notice Returns the address of the CommunityRewards contract whose grants are distributed by this contract.
  function communityRewards() external view returns (address);

  /// @notice Returns the merkle root of the merkle tree containing grant details available to accept.
  function merkleRoot() external view returns (bytes32);

  /// @notice Returns true if the index has been marked accepted.
  function isGrantAccepted(uint256 index) external view returns (bool);

  /// @notice Causes the sender to accept the grant consisting of the given details. Reverts if
  /// the inputs (which includes who the sender is) are invalid.
  function acceptGrant(
    uint256 index,
    uint256 amount,
    uint256 vestingLength,
    uint256 cliffLength,
    uint256 vestingInterval,
    bytes32[] calldata merkleProof
  ) external;

  /// @notice This event is triggered whenever a call to #acceptGrant succeeds.
  event GrantAccepted(
    uint256 indexed tokenId,
    uint256 indexed index,
    address indexed account,
    uint256 amount,
    uint256 vestingLength,
    uint256 cliffLength,
    uint256 vestingInterval
  );
}