// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// Allows anyone to claim a token using a claim-code if the code exists in a merkle root.
interface IMerkleDistributor {
    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot(address contractAddress) external view returns (bytes32);
}