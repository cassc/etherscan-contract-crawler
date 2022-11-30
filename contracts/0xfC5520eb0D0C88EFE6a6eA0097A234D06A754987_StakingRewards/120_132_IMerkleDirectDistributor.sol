// SPDX-License-Identifier: GPL-3.0-only
// solhint-disable-next-line max-line-length
// Adapted from https://github.com/Uniswap/merkle-distributor/blob/c3255bfa2b684594ecd562cacd7664b0f18330bf/contracts/interfaces/IMerkleDistributor.sol.
pragma solidity >=0.6.12;

/// @notice Enables the transfer of GFI rewards (referred to as a "grant"), if the grant details exist in this
/// contract's Merkle root.
interface IMerkleDirectDistributor {
  /// @notice Returns the address of the GFI contract that is the token distributed as rewards by
  ///   this contract.
  function gfi() external view returns (address);

  /// @notice Returns the merkle root of the merkle tree containing grant details available to accept.
  function merkleRoot() external view returns (bytes32);

  /// @notice Returns true if the index has been marked accepted.
  function isGrantAccepted(uint256 index) external view returns (bool);

  /// @notice Causes the sender to accept the grant consisting of the given details. Reverts if
  /// the inputs (which includes who the sender is) are invalid.
  function acceptGrant(
    uint256 index,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external;

  /// @notice This event is triggered whenever a call to #acceptGrant succeeds.
  event GrantAccepted(uint256 indexed index, address indexed account, uint256 amount);
}