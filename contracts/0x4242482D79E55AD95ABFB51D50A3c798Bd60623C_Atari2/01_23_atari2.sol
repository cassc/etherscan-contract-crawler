//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GFTShoppe.sol";
import "./IAccessPass.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

/// @title Atari Phase 2
/// @author Weiz
contract Atari2 is Ownable {
    GFTShoppe private originalContract;
    IAccessPass private accessTokenContract;
    uint256 private accessTokenID;
    bytes32 private root; // The merkle tree root. Used for verifying allowlist addresses

    event AidropWalletUpdated(address _from, address _newAddress);
    event AccessTokenContractAddressUpdated(address _from, address _newAddress);
    event AccessTokenIDUpdated(address _from, uint256 newID);
    event PodRoomTokenContractAddressUpdated(address _from, address _newAddress);
    event PodRoomTokenIDUpdated(address _from, uint256 newID);

    //

    constructor(address _ogContractAddress, address _accessTokenContractAddress, uint256 _accessTokenID, bytes32 _merkleroot) {
        originalContract = GFTShoppe(_ogContractAddress);
        accessTokenContract = IAccessPass(_accessTokenContractAddress);
        accessTokenID = _accessTokenID;
        root = _merkleroot;
    }

    /// @notice Updates the merkle root, used to validate the token scores
    /// @param _merkleroot The new merkle root
    function setMerkleRoot(bytes32 _merkleroot) external onlyOwner {
        root = _merkleroot;
    }

    /// @notice Updates the access token contract
    /// @param _accessTokenContractAddress The address of the new contract
    function setAccessTokenContractAddress(address _accessTokenContractAddress) external onlyOwner {
        accessTokenContract = IAccessPass(_accessTokenContractAddress);
        emit AccessTokenContractAddressUpdated(msg.sender, _accessTokenContractAddress);
    }

    /// @notice Updates the token ID
    /// @param _accessTokenID The id of the new token
    function setAccessTokenID(uint256 _accessTokenID) external onlyOwner {
        accessTokenID = _accessTokenID;
        emit AccessTokenIDUpdated(msg.sender, _accessTokenID);
    }

    /// @notice Claim your reward using unredeemed tokens
    /// @param _tokenIDs An array of unredeemed tokenIDs. Must be owned by the sender.
    /// @param _proofs An array of merkle proofs, validating the mapping between tokenID and rarity type
    function claim(uint256[] memory _tokenIDs, uint256[] memory _scores, bytes32[][] calldata _proofs) public {
        require(_tokenIDs.length == 4 && _scores.length == 4, "You must submit exactly 4.");
        require(ownedBySender(_tokenIDs), "You must own the tokens");
        require(noneAreRedeemed(_tokenIDs), "No tokens can be already redeemed");

        uint256 score = calculateScore(_tokenIDs, _scores, _proofs);

        redeemTokens(_tokenIDs);
        calculateReward(score);
    }

    /// @notice Claim your reward using unredeemed tokens
    /// @param _tokenIDs An array of unredeemed tokenIDs. Must be owned by the sender.
    /// @return noneAreRedeemed Returns true if all of the tokens are valid (unredeemed).
    function noneAreRedeemed(uint256[] memory _tokenIDs) private view returns (bool) {
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            if (originalContract.redeemedStatus(_tokenIDs[i])) { //checks if the token has already been redeemed
                return false;
            }
        }
        return true;
    }

    /// @notice Checks that all of the token IDs passed in are owned by msg.sender
    /// @param _tokenIDs An array of unredeemed tokenIDs. Must be owned by the sender.
    /// @return ownedBySender Will be true if all tokens are owned by sender, false if not.
    function ownedBySender(uint256[] memory _tokenIDs) private view returns(bool) {
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            if (originalContract.ownerOf(_tokenIDs[i]) != msg.sender) {
                return false;
            }
        }
        return true;
    }

    /// @notice Calculates the total score of all input tokens.
    /// @param _tokenIDs An array of unredeemed tokenIDs. Must be owned by the sender.
    /// @param _scores An array of token scores
    /// @param _proofs An array of merkle proofs, validating the mapping between tokenID and rarity type
    /// @return score The total score of all the input tokens.
    function calculateScore(uint256[] memory _tokenIDs, uint256[] memory _scores, bytes32[][] calldata _proofs) private view returns(uint256) {
        uint256 totalScore = 0;
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            //console.log(_tokenIDs[i], _scores[i]);
            require(_verify(_leaf(_tokenIDs[i], _scores[i]), _proofs[i]), "Score is not valid");
            totalScore += _scores[i];
        }
        return totalScore;
    }

    /// @notice Calculates the reward based on the total token score
    /// @param _score The calculated sum of all token scores
    function calculateReward(uint256 _score) private {
        if (_score >= 10400 && _score < 13000) {
            // level 1
            deliverAccessCard(1);
        } else if (_score >= 13000 && _score < 15600) {
            // level 2
            deliverAccessCard(2);
        } else if (_score >= 15600) {
            // level 3
            deliverAccessCard(3);
        }
    }

    function deliverAccessCard(uint256 _tier) private {
        accessTokenContract.mint(msg.sender, accessTokenID + _tier, 1, "0x");
    }

    function redeemTokens(uint256[] memory _tokenIDs) private {
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            originalContract.setRedeemed(_tokenIDs[i]);
        }
    }

    // Used to construct a merkle tree leaf
    function _leaf(uint256 tokenID, uint256 score)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(tokenID, score));
    }

    // Verifies a leaf is part of the tree
    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }
}