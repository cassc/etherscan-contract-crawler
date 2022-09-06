// SPDX-License-Identifier: MIT

/**
                               _
     /\                       | |
    /  \   _ __ ___   __ _  __| | ___ _   _ ___
   / /\ \ | '_ ` _ \ / _` |/ _` |/ _ | | | / __|
  / ____ \| | | | | | (_| | (_| |  __| |_| \__ \
 /_/    \_|_| |_| |_|\__,_|\__,_|\___|\__,_|___/

 @developer:CivilLabs_Amadeus
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

contract AmadeusCreatorPass is Ownable, ERC721A, ReentrancyGuard {
    constructor(
    ) ERC721A("AmadeusCreatorPass", "ACP", 1, 111) {}

    // For marketing etc.
    function reserveMint(uint256 quantity, address to) external onlyOwner {
        require(
            totalSupply() + quantity <= collectionSize,
            "Amadeus Creator Pass: Too many already minted before dev mint."
        );
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(to, maxBatchSize);
        }
        if (quantity % maxBatchSize != 0){
            _safeMint(to, quantity % maxBatchSize);
        }
    }

    // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    bool public allowListStatus = false;
    uint256 public allowListMintAmount = 111;
    uint256 public immutable maxPerAddressDuringMint = 1;

    bytes32 private merkleRoot;

    mapping(address => bool) public allowListAppeared;
    mapping(address => uint256) public allowListStock;

    function allowListMint(uint256 quantity, bytes32[] memory proof) external {
        require(allowListStatus, "Amadeus Creator Pass: Allow List Mint Not Start Yet.");
        require(totalSupply() + quantity <= collectionSize, "Amadeus Creator Pass: Reached the Max.");
        require(allowListMintAmount >= quantity, "Amadeus Creator Pass: Reached the Max For Allow List Mint.");
        require(isInAllowList(proof), "Invalid Merkle Proof.");
        if(!allowListAppeared[msg.sender]) {
            allowListAppeared[msg.sender] = true;
            allowListStock[msg.sender] = maxPerAddressDuringMint;
        }
        require(allowListStock[msg.sender] >= quantity, "Amadeus Creator Pass: Reached the Max Per Address During Allow List Mint.");
        allowListStock[msg.sender] -= quantity;
        _safeMint(msg.sender, quantity);
        allowListMintAmount -= quantity;
    }

    function setRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function setAllowListStatus(bool status) external onlyOwner {
        allowListStatus = status;
    }

    function isInAllowList(bytes32[] memory proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }
}