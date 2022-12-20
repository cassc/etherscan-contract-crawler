// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

import { SecretSanta, MerkleProof } from "../../contracts/SecretSanta.sol";

contract SecretSantaMock is SecretSanta {
    
    /*//////////////////////////////////////////////////////////////
                        TEST FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function verifyRoot(address sender, bytes32[] calldata proof_) external view returns (bool) {
        return MerkleProof.verify(proof_, allowListMerkleRoot, keccak256(abi.encodePacked(sender)));
    }

    function verifyRoot(bytes32 root, address sender, bytes32[] calldata proof_) external pure returns (bool) {
        return MerkleProof.verify(proof_, root, keccak256(abi.encodePacked(sender)));
    }

    function setMerkleRootTEST(bytes32 allowListMerkleRoot_, bytes32 tokensMerkleRoot_) external {
        allowListMerkleRoot = allowListMerkleRoot_;
        tokensMerkleRoot    = tokensMerkleRoot_;
    }

    function depositTEST(address nft, uint256 id, bytes32[] calldata proof_) external inState(State.DEPOSIT) returns (uint256 internalId_) {
        internalId_ = add(msg.sender, nft, id, false);
    }

}