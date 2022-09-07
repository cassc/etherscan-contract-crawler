// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./interfaces/IPlaybuxQuestNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract PlaybuxClaim is Ownable, Pausable, ReentrancyGuard {
    uint256 public currentSupply = 0;
    bytes32 public merkleRoot;

    mapping(address => bool) public claimed;

    IPlaybuxQuestNFT public nft;

    event Claim(address indexed account, uint256 id);

    constructor(IPlaybuxQuestNFT _nft) {
        nft = _nft;
        _pause();
    }

    function _leaf(address account, uint256 id) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, id));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function canClaim(
        address account,
        uint256 id,
        bytes32[] calldata proof
    ) public view returns (bool) {
        return _verify(_leaf(account, id), proof);
    }

    function claim(uint256 id, bytes32[] calldata proof) external whenNotPaused nonReentrant {
        require(claimed[msg.sender] == false, "Already claimed");
        require(canClaim(msg.sender, id, proof), "Invalid proof");

        // mint the nft to the user

        for (uint256 i = 0; i <= id; i++) {
            nft.mintTo(msg.sender, i + 1);
        }

        claimed[msg.sender] = true;
        emit Claim(msg.sender, id);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}