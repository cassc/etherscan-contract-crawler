//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


contract GatsbyNFT is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    
    Counters.Counter private _nextTokenId;
    
    uint public MAX_SUPPLY;
    uint public PRICE;
    uint public MAX_PER_MINT;
    uint public RESERVE_COUNT;
    
    string public baseTokenURI;
    
    constructor(string memory baseURI) ERC721("GatsbyNFT", "GNFT") {
        setBaseURI(baseURI);
        MAX_SUPPLY=1000;
        PRICE=0.0001 ether;
        MAX_PER_MINT=5;
        RESERVE_COUNT=0;
        _nextTokenId.increment();
    }
    
    function reserveNFTs() public onlyOwner {
        uint currentCount = _nextTokenId.current() - 1;

        require(currentCount.add(RESERVE_COUNT) < MAX_SUPPLY, "Not enough NFTs left to reserve");

        for (uint i = 0; i < 10; i++) {
            _mintSingleNFT();
        }
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setMaxSupply(uint supply) public onlyOwner {
        MAX_SUPPLY=supply;
    }

    function setPrice(uint price) public onlyOwner {
        PRICE=price;
    }

    function setMaxPerMint(uint maxPerMint) public onlyOwner {
        MAX_PER_MINT=maxPerMint;
    }
    
    function mintNFTs(uint _count) public payable {
        uint currentCount = _nextTokenId.current() - 1;

        require(_count > 0 && _count <= MAX_PER_MINT, "Cannot mint specified number of NFTs.");
        require(currentCount.add(_count) <= MAX_SUPPLY, "Not enough NFTs left!");
        require(msg.value >= PRICE.mul(_count), "Not enough ether to purchase NFTs.");

        for (uint i = 0; i < _count; i++) {
            _mintSingleNFT();
        }
    }
    
    function _mintSingleNFT() private {
        uint newTokenID = _nextTokenId.current();
        _safeMint(msg.sender, newTokenID);
        _nextTokenId.increment();
    }
    
    function tokensOfOwner(address _owner) external view returns (uint[] memory) {

        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint256[](tokenCount);

        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
    
    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }
    
}