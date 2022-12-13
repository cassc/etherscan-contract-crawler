// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.17;

// @notice TokenClaim taken from uniswap's TokenClaim
// Allows anyone to claim a token if they exist in a merkle root.
interface ITokenClaim {
  // Returns the merkle root of the merkle tree containing account balances available to claim.
  function merkleRoot() external view returns (bytes32);

  // Returns true if the index has been marked claimed for the given token.
  function isClaimed(address token, uint256 index) external view returns (bool);

  // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
  function claim(
    uint256 index,
    address account,
    address token,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external;

  // This event is triggered whenever a call to #claim
  event Claimed(uint256 index, address account, uint256 amount);
}