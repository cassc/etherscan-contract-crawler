// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ChadsVault is Ownable {

    mapping(address => bool) public claimed;
    bytes32 private merkleRoot;
    IERC20 CHADS = IERC20(0xDBCf42BcFC7C5390DA6Be7254dD5DB9c729110BD);
    uint256 CLAIM_AMOUNT = 0;

    function claimChads(bytes32[] calldata _merkleProof) external {
        require(merkleRoot != "", "Whitelist not set yet");
        require(!claimed[msg.sender], "Already claimed tokens");
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof. Not whitelisted.");

        CHADS.transfer(msg.sender,CLAIM_AMOUNT);
        
        claimed[msg.sender] = true;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
    * @notice Set the amount of claimable CHADS in WEI.
    *
    * @param _amount claimable amount per wallet, in WEI.
    */
    function setClaimAmount(uint256 _amount) external onlyOwner {
        CLAIM_AMOUNT = _amount;
    }

}