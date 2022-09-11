// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AIPudgys is ERC721A, Ownable {
    using Strings for uint256;

    // Constants
    uint256 public TOTAL_SUPPLY = 8888;
    uint256 public MINT_PRICE = 0.0025 ether;
    uint256 public FREE_ITEMS_COUNT = 2500;
    uint256 public MAX_IN_TRX = 2;
    address payable withdrawTo = payable(0xCc92F5DA26f156681fa6EeE8E63BfEEc605D228f);


    // Variables
    string public baseTokenURI;
    string  public uriSuffix;
    bool public paused = false;
    bool public revealed = false;
    string public revealImage;



    constructor(string memory _initBaseURI, string memory _revealImage, string memory _uriSuffix) ERC721A("AIPudgys", "AIP") {
        setBaseTokenURI(_initBaseURI);
        setRevealImage(_revealImage);
        setUriSuffix(_uriSuffix);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (!revealed) {
            return revealImage;
        }

        return
            string(abi.encodePacked(_baseURI(), (tokenId + 10000).toString(), uriSuffix));
    }

    function mintItem(uint256 quantity) external payable {
        uint256 supply = totalSupply();
        require(!paused, "Minting is paused.");
        require((quantity > 0) && (quantity <= MAX_IN_TRX), "Invalid quantity.");
        require(supply + quantity <= TOTAL_SUPPLY, "Exceeds maximum supply.");

        if (msg.sender != owner()) {
            require((supply + quantity <= FREE_ITEMS_COUNT) || (msg.value >= MINT_PRICE * quantity), "Not enough supply.");
        }

        _safeMint(msg.sender, quantity);
    }


    function mintTo(address to,uint256 quantity) external payable onlyOwner{
        uint256 supply = totalSupply();
        require(supply + quantity - 1 <= TOTAL_SUPPLY, "Exceeds maximum supply");
        _safeMint(to, quantity);
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = withdrawTo.call{value: address(this).balance}("");
        require(os);
    }

    function setCost(uint256 _newCost) public onlyOwner {
        MINT_PRICE = _newCost;
    }

    function setFreeCount(uint256 _count) public onlyOwner {
        FREE_ITEMS_COUNT = _count;
    }

    function setMaxInTRX(uint256 _total) public onlyOwner {
        MAX_IN_TRX = _total;
    }

    function setmaxMintAmount(uint256 _count) public onlyOwner {
        TOTAL_SUPPLY = _count;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setRevealImage(string memory _revealImage) public onlyOwner {
        revealImage = _revealImage;
    }
}