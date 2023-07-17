// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RickRainbows is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 private constant PRICE = 10000000000000000; // 0.01 ETH
    uint256 public constant MAX_RICK_SUPPLY = 10000;

    uint256 public startingIndex = 0;
    bool public hasSaleBegun = false;    
    bool public isMetadataLocked = false;    
    address private _owner;
    
    string private _baseTokenUri;
    string private _baseTokenExtension;    

    // ===============================================================

    constructor() ERC721("Rick Rainbows", "RICK") {
        _owner = msg.sender;
        _baseTokenUri = "https://fuckbubbles.wtf/";
        _baseTokenExtension = ''; 
    }


    function mintRickRainbow(uint256 numberOfRicks) public payable nonReentrant {
        require(hasSaleBegun, "Sale has not yet started");        
        require(totalSupply() < MAX_RICK_SUPPLY, "The sale has now ended");
        require(numberOfRicks > 0, "Cannot buy zero Rick Rainbows");        
        require(
            (totalSupply() + numberOfRicks) <= MAX_RICK_SUPPLY,
            "Exceeds MAX_RICK_SUPPLY"
        );
        require(
            (PRICE * numberOfRicks) == msg.value,
            "ETH sent is not correct"
        );

        for (uint256 i = 0; i < numberOfRicks; i++) {
            _safeMint(msg.sender, totalSupply());
        }

    }
  
    function withdraw(uint256 amount) public onlyOwner nonReentrant {
        require(
            (amount > 0) && (amount <= address(this).balance),
            "Invalid amount"
        );

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "ETH Transfer Failed");
    }

    function beginSale() public onlyOwner {
        hasSaleBegun = true;
    }        

    function lockMetadata() public onlyOwner {
        isMetadataLocked = true;
    }    

    function setTokenURI(string memory newUri) public onlyOwner {
        require(!isMetadataLocked, "Metdata has been locked, cannot change");
        _baseTokenUri = newUri;
    }
    
    function setTokenExtension(string memory extension) public onlyOwner {
        require(!isMetadataLocked, "Metdata has been locked, cannot change");        
        _baseTokenExtension = extension;
    }    


    function indexedTokenURI(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    _baseTokenUri,
                    tokenId.toString(),
                    _baseTokenExtension
                )
            );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {

 
     require(_exists(tokenId), "Unknown tokenId");

        string memory result;
        uint256 mappedTokenId = (tokenId + startingIndex) % MAX_RICK_SUPPLY;
        result = indexedTokenURI(mappedTokenId);
        
        return result;
    }
}