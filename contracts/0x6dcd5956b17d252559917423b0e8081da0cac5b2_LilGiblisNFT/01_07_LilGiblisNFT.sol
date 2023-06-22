//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract LilGiblisNFT is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    uint256 public MAX_SUPPLY = 5000;
    uint256 MAX_PER_MINT = 10; 

    uint256 public totalSupply = MAX_SUPPLY;

    uint256 private PRICE = 0 ether;
    bool public isSaleActive = true;

    string public baseTokenURI;

    mapping(address => uint256) private _allowList; //WHITE LIST


    constructor(string memory baseURI) ERC721("LilGiblisNFT", "LGNFT") {
        setBaseURI(baseURI);
    }

    function pauseSale() public onlyOwner {
        require(isSaleActive == true, "sale is already paused");
        isSaleActive = false;
    }

    function startSale() public onlyOwner {
        require(isSaleActive == false, "sale is already started");
        isSaleActive = true;
    }


    function reserveNFT() public onlyOwner {
        uint totalMinted = _tokenIds.current();
        require(totalMinted < MAX_SUPPLY, "Not enough NFTs");
    
        _mintSingleNFT();
    }

    function reserveTwentyFiveNFTs() public onlyOwner {
        uint totalMinted = _tokenIds.current();
        require(totalMinted.add(25) < MAX_SUPPLY, "Not enough NFTs left to reserve");

        for (uint i = 0; i < 25; i++) {
            _mintSingleNFT();
        }
    }

    function _baseURI() internal view returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    } 

    function mintNFTs(uint _count) public payable {
        uint totalMinted = _tokenIds.current();

        require(totalMinted.add(_count) <= MAX_SUPPLY, "Not enough NFTs!");
        require(_count > 0 && _count <= MAX_PER_MINT, "Cannot mint specified number of NFTs.");
        require(msg.value >= PRICE.mul(_count), "Not enough ether to purchase NFTs.");
        require(isSaleActive == true, "sale is already paused");

        for (uint i = 0; i < _count; i++) {
            _mintSingleNFT();
        }
    }

    function _mintSingleNFT() private {
        uint newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);
        _tokenIds.increment();
        totalSupply--;
    }

    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");
        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
       return string(abi.encodePacked(baseTokenURI, Strings.toString((tokenId)), '.json'));
    }
}