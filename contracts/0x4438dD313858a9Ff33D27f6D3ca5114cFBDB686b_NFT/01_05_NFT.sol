//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721A, Ownable {
    string private m_baseURI;
    string private m_contactMetadataURI;
    uint256 private m_maxSupply;
    uint256 private m_tokenPrice;
    uint256 private m_mintLimit;
    constructor(string memory name, string memory symbol, string memory baseURI, 
    string memory contractMetadataURI, uint256 tokenPrice, uint256 maxSupply, uint256 mintLimit) 
    ERC721A(name, symbol) {
        m_maxSupply = maxSupply;
        m_tokenPrice = tokenPrice;
        m_baseURI = baseURI;
        m_contactMetadataURI = contractMetadataURI;
        m_mintLimit = mintLimit;
    }

    function setLimit(uint256 mintLimit) external onlyOwner {
        require(mintLimit > m_mintLimit, "The new mint limit must be higher than the old limit");
        m_mintLimit = mintLimit;
    }

    function withdraw(uint256 value) external onlyOwner {
        payable(msg.sender).transfer(value);
    }

    function setPrice(uint256 tokenPrice) external onlyOwner {
        m_tokenPrice = tokenPrice;
    }

    function price() external view returns (uint256) {
        return m_tokenPrice;
    }

    function mint(uint256 quantity) external payable {
        require(quantity + _totalMinted() <= m_mintLimit, "Cannot mint more than the mint limit");
        require(quantity + _totalMinted() <= m_maxSupply, "Cannot mint more than the max supply");
        require(msg.value >= m_tokenPrice * quantity, "Not enough ether was sent to mint this amount of tokens");
        _mint(msg.sender, quantity);
    }

    function reserve(uint256 quantity) external onlyOwner {
        require(quantity + _totalMinted() <= m_mintLimit, "Cannot reserve more than the mint limit");
        require(quantity + _totalMinted() <= m_maxSupply, "Cannot reserve more than the max supply");
        _mint(msg.sender, quantity);
    }

    function updateNFTs(string memory baseURI, uint256 maxSupply) public onlyOwner {
        require(maxSupply >= m_maxSupply, "The new max supply must be larger or equal than the old one");
        m_maxSupply = maxSupply;
        m_baseURI = baseURI;
    }

    function contractURI() public view returns (string memory) {
        return m_contactMetadataURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return m_baseURI;
    }
}