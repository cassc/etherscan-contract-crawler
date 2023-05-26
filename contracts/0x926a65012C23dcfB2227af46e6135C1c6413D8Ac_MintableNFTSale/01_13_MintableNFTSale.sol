// Based loosely on galaxyEggs
// https://etherscan.io/address/0xa08126f5e1ed91a635987071e6ff5eb2aeb67c48#code

/**
 * Generic Mintable NFT Sale contract
 * Create a collection with the following variables
 * - max supply - max number of nfts
 * - price - per nft
 * - Max items per mint
 * - pre mint - number of NFTs that can be preminted for free, by whitelisted users, or in a batch for admins e.g. for giveaways
 * - free mint - number of nfts to allow users to mint for free
 * Allow users to mint for a given price
 * Contract accumulates ETH from sales
 * Accumulated ETH can be withdrawn to a EOA or paymentSplitter to split gains across many users using withdrawAllToSplitter
 *
 * Admins can set the baseTokenURI before or after a drop
 * Setting the baseTokenURI after a drop, allows the contract to sell off NFTs with different rarities with the same price without cheating
 *
 * Advantages:
 - specify a price and change it later
 - create a limited supply collection, and add new items later
 - cheaper than rarible nft factory? 
 - add royalties on opensea and rarible later when the collection is imported
 */

// Modified to reduce code size from:
/**
 |  MintableNFTSale                            ·     14.382  │
+ 
 |  PaymentSplitter                            ·      1.520  │
 => 15.902

 to  8.45
  */
// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract MintableNFTSale is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public PRICE;
    uint256 public MAX_SUPPLY;
    uint256 public MAX_PER_MINT;
    bool public can_mint;

    string private _baseTokenURI;

    address payable private _artist;
    address payable private _benefactor;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _price, // Price of each NFT in ETH, 1 ETH = 1e18 or 1 followed by 18 0s
        uint256 _maxSupply, // max supply of the nfts
        uint256 _maxPerMint, // max no. of nfts a user can mint in a single tx. also max they can mint into 1 wallet
        address artist // artist address
    ) ERC721(_name, _symbol) {
        PRICE = _price;
        MAX_SUPPLY = _maxSupply;
        MAX_PER_MINT = _maxPerMint;
        _artist = payable(artist);
        _benefactor = payable(owner());

        // Mint 5 to artist, 5 to owner, + 5 to owner for raffle
        for (uint256 i; i < 5; i++) {
            _mint(_artist, i);
        }
        for (uint256 j = 5; j < 15; j++) {
            _mint(_benefactor, j);
        }
    }

    receive() external payable {}

    fallback() external payable {}

    function updateParams(uint256[] memory numericParams) external onlyOwner {
        PRICE = numericParams[0];
        MAX_SUPPLY = numericParams[1];
        MAX_PER_MINT = numericParams[2];
    }

    function toggleMint() external onlyOwner {
        can_mint = !can_mint;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() external {
        // Split payment 50/50 between artist and owner
        // Owner shares will then be partly redirected to DAO
        uint256 half = address(this).balance / 2;
        Address.sendValue(_benefactor, half);
        Address.sendValue(_artist, half);
    }

    function mint(uint256 num) public payable {
        require(can_mint, "mint paused");

        uint256 supply = totalSupply();

        require(num <= MAX_PER_MINT, "2 many:call");
        require(balanceOf(msg.sender) + num <= MAX_PER_MINT, "2 many:user"); // max n tokens per user
        require(supply + num <= MAX_SUPPLY, "overlimit");
        require(msg.value >= PRICE * num, "2 cheap");

        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "INVALID");

        string memory baseURI = getBaseURI();

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function getBaseURI() public view returns (string memory) {
        return _baseTokenURI;
    }
}