// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Whitelist {
    // Whitelist params
    uint256 public whitelistMintSupply;
    uint256 public whitelistMintQuantity;

    uint256 public whitelistMintPrice;

    bytes32 public merkleRoot;
    
    error ProofFailed();
    error WhitelistMintSoldOut();

    modifier checkMerkleProof(address _address, bytes32[] calldata _merkleProof) {
        bool proofVerified = MerkleProof.verify(
            _merkleProof,
            merkleRoot,
            keccak256(abi.encodePacked(_address))
        );
        if (!proofVerified)
            revert ProofFailed();
        _;
    }

    modifier checkWhitelistMintQuantity(uint8 _quantity) {
        if (whitelistMintSupply != 0){
            // Checking if the required quantity of tokens still remains
            uint256 remainingSupply = whitelistMintSupply - whitelistMintQuantity;
            if (_quantity > remainingSupply)
                revert WhitelistMintSoldOut();
            _;
        }
        _;
    }

    // Set Merle Root
    function _setMerkleRoot(bytes32 _merkleRoot) internal {
        merkleRoot = _merkleRoot;
    }

    function _setWhitelistMintSupply(uint256 _whitelistMintSupply) internal {
        whitelistMintQuantity = 0;
        whitelistMintSupply = _whitelistMintSupply;
    }

    function _setWhitelistMintPrice(uint256 _whitelistMintPrice) internal {
        whitelistMintPrice = _whitelistMintPrice;
    }
}