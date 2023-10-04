// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract NFTmint is ERC721Enumerable, Ownable {

    string public baseTokenURI;
    uint16 public constant TOTAL_MINT_AMOUNT = 30;
    // uint256 public pricePerNft = 0.01 ether;
    uint256 public pricePerNft = 10000000000000000;
    mapping(address => uint256) public mintedNfts;

    constructor (string memory baseURI)
        ERC721 ("Deputy Dawgs Project", "DDAWG")
    {
        setBaseURI(baseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Set the base URI for token
    function setBaseURI (string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    // Set the price per NFT
    function setPricePerNft (uint256 _pricePerNft) public onlyOwner {
        pricePerNft = _pricePerNft;
    }

    // Public slae without whitelist
    function publicMint() public payable {
        uint256 mintIndex;

        require(msg.sender == tx.origin, "Mint from other contract not allowed.");
        require(mintedNfts[msg.sender] < 1, "You already mint a NFT.");
        require(totalSupply() <= TOTAL_MINT_AMOUNT, "Public sale is finished.");
        require(msg.value >= pricePerNft, "Insufficient payment.");

        mintIndex = totalSupply() + 1;
        _safeMint(msg.sender, mintIndex);
        mintedNfts[msg.sender] = mintIndex;
    }

    function withdraw(address payable ownerWallet) external onlyOwner {
        require(ownerWallet != address(0), "Invalid address.");
        ownerWallet.transfer(address(this).balance);
    }
}