// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);

    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);

    // Returns the amount of gas rebate allocated to claimants.
    function gasRebate() external view returns (uint256);

    // Sets the amount of gas rebate to allocate to claimants.
    function setGasRebate(uint256 _gasRebate) external;

    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index) external view returns (bool);

    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(uint256 index, address payable account, uint256 ethAmount, uint256 tokenAmount, bytes32[] calldata merkleProof) external;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account, uint256 ethAmount, uint256 tokenAmount);
}

interface IMultiTokenMerkleDistributor {
    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);

    // Returns the amount of gas rebate allocated to claimants.
    function gasRebate() external view returns (uint256);

    // Sets the amount of gas rebate to allocate to claimants.
    function setGasRebate(uint256 _gasRebate) external;

    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index) external view returns (bool);

    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(uint256 index, address payable account, uint256 ethAmount, uint256[] calldata tokenAmounts, bytes32[] calldata merkleProof) external;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account, uint256 ethAmount, uint256[] tokenAmounts);
}