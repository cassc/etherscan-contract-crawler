//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../AdventurersStorage.sol";

/// @title Whitelist.sol
/// @author @Dadogg80 - Viken Blockchain Solutions.
/// @notice Whitelist.sol will allow the "whitelisted accounts to mint their pre-allocated amount of adventurers.
/// @dev The main methods in this contract are [ setMerkleRoot } and { mintSelected }, read more about the methods in their description.

abstract contract WhiteList is AdventurersStorage {

    mapping (address => bool) internal whitelistUsed;
    mapping (address => uint256) internal whitelistRemaining;
    

    bytes32 internal merkleRoot;
    uint256 public maxItemsPerTx = 2;
    uint256 internal price;

    /// @notice Allow whitelisted accounts to mint according to the merkletree.
    /// @param amount The amount of nft's to mint.
    /// @param totalAllocation The allocated amount to mint.
    /// @param leaf the leaf node of the three.
    /// @param proof the proof from the merkletree.
    function mintSelected(uint amount, uint totalAllocation, bytes32 leaf, bytes32[] memory proof) external payable {
        require(msg.value == price, "wrong amount!");

        // Create storage element tracking user mints if this is the first mint for them
        if (!whitelistUsed[msg.sender]) {
            // Verify that (msg.sender, amount) correspond to Merkle leaf
            require(keccak256(abi.encodePacked(msg.sender, totalAllocation)) == leaf, "don't match Merkle leaf");

            // Verify that (leaf, proof) matches the Merkle root
            require(verify(merkleRoot, leaf, proof), "Not a valid leaf");

            whitelistUsed[msg.sender] = true;
            whitelistRemaining[msg.sender] = totalAllocation;
        }

        // Require nonzero amount
        require(amount > 0, "Can't mint zero");
        require(amount <= maxItemsPerTx, "Above MaxItemsPerTx");

        require(whitelistRemaining[msg.sender] >= amount, "more than remaining allocation");
 
        whitelistRemaining[msg.sender] -= amount;
        _mint(msg.sender, amount);
        emit MintSelected(msg.sender, amount);
    }

    /// @notice verify the merkleProof.
    /// @param root the root node in the merkletree.
    /// @param leaf The leaf node in the merkletree.
    /// @param proof The proof in the merkletree.
    function verify(bytes32 root, bytes32 leaf, bytes32[] memory proof) public pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMintSelectedActive(bool result, uint _price) external onlyOwner {
        mintSelectedActive = result;
        price = _price;
    }

}