// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BROKeNToKENS is ERC721Enumerable, Ownable {
    using Strings for uint256;

    // Constant variables
    // ------------------------------------------------------------------------
    uint256 public constant MAX_SUPPLY = 1000;


    // URI variables
    // ------------------------------------------------------------------------
    string private _contractURI;
    string private _baseTokenURI;


    // Events
    // ------------------------------------------------------------------------
    event BaseTokenURIChanged(string baseTokenURI);
    event ContractURIChanged(string contractURI);


    // Constructor
    // ------------------------------------------------------------------------
    constructor() ERC721("BROKeN ToKENS", "BROKENTOKEN") {}


    // Mint function
    // ------------------------------------------------------------------------    
    function mint(uint256 numberOfTokens, address receiver) external onlyOwner {
        require(totalSupply() < MAX_SUPPLY, "Sold out");   
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(receiver, totalSupply() + 1);
        }
    }


    // Base URI Functions
    // ------------------------------------------------------------------------
    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
        emit ContractURIChanged(URI);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function setBaseTokenURI(string calldata URI) external onlyOwner {
        _baseTokenURI = URI;
        emit BaseTokenURIChanged(URI);
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }
}