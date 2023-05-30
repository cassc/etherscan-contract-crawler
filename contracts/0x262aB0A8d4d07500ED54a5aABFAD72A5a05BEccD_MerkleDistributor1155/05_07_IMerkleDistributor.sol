// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);

    // Returns claimed amount if the address has been marked claimed.
    function claimedAmount(address user) external view returns (uint256);

    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(uint256 amount, bytes32[] calldata merkleProof) external;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(address user, uint256 amount);
}