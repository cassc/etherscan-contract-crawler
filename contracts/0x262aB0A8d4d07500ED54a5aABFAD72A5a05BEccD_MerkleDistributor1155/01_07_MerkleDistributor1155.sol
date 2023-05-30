// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IMerkleDistributor.sol";
import "./ISuper1155.sol";

contract MerkleDistributor1155 is IMerkleDistributor, Ownable, Pausable {
    address public immutable override token;

    bytes32 public merkleRoot;

    mapping(address => uint256) private claimed;

    constructor(address _token) {
        token = _token;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function claimedAmount(
        address user
    ) public view override returns (uint256) {
        return claimed[user];
    }

    function claim(
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external override whenNotPaused {
        require(
            claimed[msg.sender] < amount,
            "MerkleDistributor: Drop already claimed."
        );

        bytes32 leaf = keccak256(abi.encode(msg.sender, amount));

        // Check the merkle proof
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "MerkleDistributor: Invalid proof."
        );
        uint256 claimingAmount = amount - claimed[msg.sender];
        claimed[msg.sender] = amount;
        // Mark it claimed and send the token.
        ISuper1155(token).mint(msg.sender, claimingAmount);
        emit Claimed(msg.sender, claimingAmount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}