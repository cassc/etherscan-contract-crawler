// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract VesuvioNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint;
    Counters.Counter private _tokenIdCounter;

    string public baseURI;
    uint256 public MAX_SUPPLY = 42;
    uint256 public saleStartTime = 1646737200;
    address public minter;


    constructor(string memory _baseURI) ERC721("Vesuv.io", "SUN") {
        baseURI = _baseURI;
       
    }

    function publicMint(address to,uint256 auctionID) public {
        
        require(msg.sender == minter, "Only minter can mint");
    
        require(!_exists(auctionID), "Token Already Exists");
        require(auctionID >= 1 && auctionID <= MAX_SUPPLY, "Invalid Auction ID");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, auctionID);
    }


    function safeMint(address to) public onlyOwner {
    
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function setMinter(address minter_) public onlyOwner {
        minter = minter_;
    }


    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }



    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");


        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }


    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}