pragma solidity 0.8.6;

// SPDX-License-Identifier: MIT

interface IMerkleVault {
    event MerkleTreeUpdated(uint256 newVersion);
    event ETHReceived(uint256 amount);
    event TokensClaimed(address indexed token, uint256 amount);

    function claim(uint256 _index, address _token, uint256 _amount, bytes32[] calldata _merkleProof) external;
}