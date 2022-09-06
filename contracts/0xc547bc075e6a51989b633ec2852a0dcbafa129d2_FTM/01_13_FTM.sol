// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract FTM is ERC721A, Ownable, ReentrancyGuard
{
    using Strings for string; 

    uint public constant MAX_TOKENS = 6969;
    uint256 public constant PRICE = 0.0069 ether; 
    uint public constant SALE_LIMIT = 20;

    string private _baseTokenURI; // The Base URI is the link copied from your IPFS Folder holding your collections json files that have the metadata and image links associated to each token ID
    string public notRevealedUri; // This is your placeholder URI to add an image, gif, or video prior to reveal that will display on all editions on opensea
    bool revealed = false;

    constructor() ERC721A("FOR THE MUSCLES", "FTM") { }

    function mintToken(uint256 amount) external payable
    {
        require(amount > 0 && amount <= SALE_LIMIT, "m20"); // Max 20 NFTs per transaction
        require(totalSupply() + amount <= MAX_TOKENS, "Pems"); // Purchase would exceed max supply
        require(msg.value >= PRICE * amount, "NET"); // Not enough ETH for transaction

        _safeMint(msg.sender, amount);
    }

    function withdraw() external nonReentrant
    {
        require(msg.sender == owner(), "is"); // Invalid sender
        (bool success1, ) = owner().call{value: address(this).balance}("");
        require(success1, "wf"); // Withdraw failed
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "bt"); // ERC721Metadata: URI query for nonexistent token

        if(revealed == false)
        {
            return notRevealedUri;
        }

        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }

    function setNotRevealedURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setRevealed() external onlyOwner {
        revealed = true;
    }
}