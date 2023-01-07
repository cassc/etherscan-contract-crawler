// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// use merkleProof
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract NuoMerkle {
    // merkle claimed data set
    mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMaps;
    mapping(uint256 => bytes32) public merkleRoots;

    /// rertieve if the nth tree's index has claimed
    function isClaimed(uint256 treeId, uint256 index)
        public
        view
        returns (bool)
    {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMaps[treeId][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    /// set the exact pool's index was claimed
    function _setClaimed(uint256 treeId, uint256 index) internal {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMaps[treeId][claimedWordIndex] =
            claimedBitMaps[treeId][claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    // only for dev time
    function verify(
        bytes32 _merkleRoot,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public pure returns (bool) {
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        return MerkleProof.verify(merkleProof, _merkleRoot, node);
    }

    /**
     * @notice  user claim using merkle proof, providing info to the contract
                be sure，u must ensure that the account is verified to be the sender!
     * @dev
     * @param   treeId  pick the root from the multiple tree maps
     * @param   index   the tree leaf index
     * @param   account the user address, ofcourse, it shall be the msg.sender
     * @param   amount  uint256 amount for user to claim
     * @param   merkleProof  the tree generated proof data
     */
    function merkleVerifyAndSetClaimed(
        uint256 treeId,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) internal returns (bool claimed) {
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoots[treeId], node),
            "MerkleDistributor: Invalid proof."
        );
        claimed = isClaimed(treeId, index);
        
        // Mark it claimed and send the token.
        if(!claimed) {
            _setClaimed(treeId, index);
        }
    }
}