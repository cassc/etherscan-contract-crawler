// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract MagicBoy is Ownable, ERC721A, ReentrancyGuard {

    uint public maxSupply = 233;

    constructor(
    ) ERC721A("MagicBoy", "MBNFT", 5, 233) {
        _baseTokenURI = "ipfs://Qmboiavj5sY3fseFhJX4iT19v31htghmPun9fET1phYv9b/";
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setMaxSupply(uint newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
    }

    function publicMint(uint256 quantity) external payable callerIsUser {
        require(quantity<=5, "reached max supply");
        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        require(
            numberMinted(msg.sender) + quantity <= 5,
            "can not mint this many"
        );
        _safeMint(msg.sender, quantity);
    }

    // // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
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
}