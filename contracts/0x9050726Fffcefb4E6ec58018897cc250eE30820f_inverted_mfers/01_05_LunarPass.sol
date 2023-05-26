// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract inverted_mfers is ERC721A, Ownable {
    uint256 MAX_SUPPLY = 10000; 
    uint256 public mintRate = 0.005 ether;
    uint256 public mintRateSafe = mintRate;
    bool public revealed = false; // for one json and one video
    string public notRevealedUri; // for one json and one video

    string public baseURI = "ipfs://QmYwHocpjddeWx1NZw7cd3YSoR2y8JJy85A2HYDkFm1HX6/LunarPass.json"; // Copy paste this text in deploy input without " "
    
    constructor(string memory _initNotRevealedUri)
        ERC721A("Lunar Pass", "LUNA")
    {
        setNotRevealedURI(_initNotRevealedUri);
    }

    function mint(uint256 quantity) external payable {
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Not enough tokens left"
        );

        if (_totalMinted() < 2000) {
             mintRate = 0 ether;
             require(msg.value >= (mintRate * quantity), "Not enough ether sent");
            _safeMint(msg.sender, quantity);
        } else {
            mintRate = mintRateSafe;
            require(msg.value >= (mintRate * quantity), "Not enough ether sent");
            _safeMint(msg.sender, quantity);
        }
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setPrice(uint256 _mintRate) public onlyOwner {
        mintRate = _mintRate;
        mintRateSafe = _mintRate;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return notRevealedUri; 
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
}