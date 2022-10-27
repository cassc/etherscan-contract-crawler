// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

library MerkleTree {
    struct UpFrontMerkleData {
        uint256 index;
        address account;
        uint256 amount;
        bytes32[] merkleProof;
    }

    struct TrackClaimed {
        mapping(uint256 => uint256) claimedBitMap;
    }

    /**
     * @dev a function that checks if the index leaf node is valid and if the user has purchased.
     * will set the index node to purchased if approved
     */
    function purchaseMerkleAmount(
        UpFrontMerkleData calldata merkleData,
        TrackClaimed storage self,
        uint256 _purchaseTokenAmount,
        bytes32 merkleRoot
    ) external {
        require(!hasPurchasedMerkle(self, merkleData.index), "Already purchased tokens");
        require(msg.sender == merkleData.account, "cant purchase others tokens");
        require(merkleData.amount >= _purchaseTokenAmount, "purchasing more than allowance");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(merkleData.index, merkleData.account, merkleData.amount));
        require(MerkleProof.verify(merkleData.merkleProof, merkleRoot, node), "MerkleTree.sol: Invalid proof.");

        // Mark it claimed and send the token.
        _setPurchased(self, merkleData.index);
    }

    /**
     * @dev sets the claimedBitMap to true for that index
     */
    function _setPurchased(TrackClaimed storage self, uint256 _index) private {
        uint256 claimedWordIndex = _index / 256;
        uint256 claimedBitIndex = _index % 256;
        self.claimedBitMap[claimedWordIndex] = self.claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    /**
     * @dev returns if address has purchased merkle
     * @return bool index of the leaf node has purchased or not
     */
    function hasPurchasedMerkle(TrackClaimed storage self, uint256 _index) public view returns (bool) {
        uint256 claimedWordIndex = _index / 256;
        uint256 claimedBitIndex = _index % 256;
        uint256 claimedWord = self.claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }
}