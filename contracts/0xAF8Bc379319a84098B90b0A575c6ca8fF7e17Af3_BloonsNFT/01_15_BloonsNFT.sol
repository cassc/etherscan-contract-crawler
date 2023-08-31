// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BloonsNFT is ERC721, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public constant MAX_SUPPLY = 1200;
    uint256 public constant MINT_PRICE = 0.02 ether;

    string private _defaultBaseURI = "https://ipfs.io/ipfs/QmU87fLFRVPA5VcB9xigSvrCtWqY55BHD5ncXzSGzgknJU/";
    string public contractURI = "https://ipfs.io/ipfs/QmcqtF4RNrfSWJAiJ15Zb6JDiyz1BaPyUvAxmvBcWFHHMd";  // Replace with your default contract URI


    constructor() ERC721("BloonsNFT", "BLOONS") {}

    function _baseURI() internal view override returns (string memory) {
        return _defaultBaseURI;
    }

    function safeMint(address to) private {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function mintMultiple(address to, uint256 numberOfTokens) public payable {
        require(numberOfTokens <= 20, "Can mint up to 20 tokens at a time");
        require(_tokenIdCounter.current() + numberOfTokens <= MAX_SUPPLY, "Would exceed max supply");
        require(msg.value == MINT_PRICE * numberOfTokens, "Incorrect Ether sent");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            safeMint(to);
        }
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _defaultBaseURI = newBaseURI;
    }

    function setContractURI(string memory newContractURI) public onlyOwner {
        contractURI = newContractURI;
    }

    function getCount() public view returns (uint256) {
        return _tokenIdCounter.current();
    }
}