// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract WorldWideGESTURE is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string public baseURI;
    uint256 public constant maxSupply = 333;
    uint256 public constant userLimit = 100;
    bool public isSaleActive = false;

    constructor() ERC721("WorldWide GESTURE", "WG") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _safeMint(address to) private {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function mint(uint256 mintAmount) public payable{
        require(_tokenIdCounter.current() + mintAmount <= maxSupply, "I'm sorry we reached the cap");
        require(isSaleActive, "Sale is not active" );
        require(mintAmount > 0, "Minimum one amount");
        require(balanceOf(msg.sender) + mintAmount <= userLimit, "I'm sorry only three NFT per user");
        require(msg.value >= 0.0088 ether * mintAmount, "Enought value");

        for(uint256 i; i < mintAmount; i++){
            _safeMint(msg.sender);
        }
    }

    function withdrawMoneyTo(address payable _to) public onlyOwner{
        _to.transfer(address(this).balance);
    }

    function setIsActive(bool isActive) public onlyOwner{
        isSaleActive = isActive;
    } 

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
}