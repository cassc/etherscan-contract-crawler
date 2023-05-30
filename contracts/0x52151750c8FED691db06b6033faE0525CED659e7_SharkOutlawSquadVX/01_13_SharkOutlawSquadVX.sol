//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SharkOutlawSquadVX is Ownable, ERC721Enumerable {
    using Strings for uint256;

    // Specification
    uint256 public NOPIXEL_MINT_PRICE = 0.2 ether;

    // Path to genesis and pixel smart contract
    address public _genesisSmartContract;
    address public _pixelSmartContract;
    string private _contractURI;
    string private _tokenBaseURI;

    // Sales status
    bool public isSalesActivated;

    constructor() ERC721("Shark Outlaw Squad VX", "SHARKVX") {}

    function mintWithPixel(uint256 tokenId) external {
        require(isSalesActivated, "Public sale is closed");
        require(
            ERC721(_genesisSmartContract).ownerOf(tokenId) == msg.sender,
            "Not genesis owner"
        );
        require(
            ERC721(_pixelSmartContract).ownerOf(tokenId) == msg.sender,
            "Not pixel owner"
        );
        _safeMint(msg.sender, tokenId);
    }

    function mintWithoutPixel(uint256 tokenId) external payable {
        require(isSalesActivated, "Public sale is closed");
        require(
            ERC721(_genesisSmartContract).ownerOf(tokenId) == msg.sender,
            "Not genesis owner"
        );
        require(msg.value >= NOPIXEL_MINT_PRICE, "Insufficient ETH");
        _safeMint(msg.sender, tokenId);
    }

    function changeNoPixelPrice(uint256 price)
        external
        onlyOwner
        returns (uint256)
    {
        NOPIXEL_MINT_PRICE = price;
        return NOPIXEL_MINT_PRICE;
    }

    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "No amount to withdraw");
        payable(msg.sender).transfer(address(this).balance);
    }

    function togglePublicSalesStatus() external onlyOwner {
        isSalesActivated = !isSalesActivated;
    }

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    function setGenesisContractAddress(address genesisAddress)
        external
        onlyOwner
    {
        _genesisSmartContract = genesisAddress;
    }

    function setPixelContractAddress(address pixelAddress) external onlyOwner {
        _pixelSmartContract = pixelAddress;
    }

    // To support Opensea contract-level metadata
    // https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    // To support Opensea token metadata
    // https://docs.opensea.io/docs/metadata-standards
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(_tokenId), "Token not exist");

        return string(abi.encodePacked(_tokenBaseURI, _tokenId.toString()));
    }
}