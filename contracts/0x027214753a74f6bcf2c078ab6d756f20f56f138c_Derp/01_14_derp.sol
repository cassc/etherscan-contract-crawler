// SPDX-License-Identifier: MIT

//  author Name: Alex Yap
//  author-email: <[email protected]>
//  author-website: https://alexyap.dev

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Derp is ERC721Enumerable, ReentrancyGuard, Ownable {

    string public DERP_PROVENANCE = "";
    string public baseTokenURI;
    bool public mintIsActive = false;
    bool public mintFreeClaimIsActive = false;
    uint256 adminReserved = 1000;
    uint256 paidReserved = 3000;
    uint256 freeReserved = 5000;
    uint256 adminMinted;
    uint256 public paidMinted;
    uint256 public freeMinted;
    uint256 public freeClaimMaxMint = 1;
    uint256 public derpPrice;
    uint256 public derpMaxPerMint;
    uint256 public constant MAX_DERP = 9000;
    mapping(address => uint256) public freeClaimMinted;
    
    //events
    event NameChanged(string name, uint256 tokenId);

    constructor(string memory baseURI, uint256 _mintPrice, uint256 _maxPerMint) ERC721("Derp", "DERP") {
        setBaseURI(baseURI);
        derpPrice = _mintPrice;
        derpMaxPerMint = _maxPerMint;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setPrice(uint256 _mintPrice) external onlyOwner {
        derpPrice = _mintPrice;
    }

    function setMaxPerMint(uint256 _maxPerMint) external onlyOwner {
        derpMaxPerMint = _maxPerMint;
    }

    function setFreeClaimMaxMint(uint256 _max) external onlyOwner {
        freeClaimMaxMint = _max;
    }

    function flipMintState() public onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function flipFreeClaimMintState() public onlyOwner {
        mintFreeClaimIsActive = !mintFreeClaimIsActive;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        DERP_PROVENANCE = provenanceHash;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        payable(msg.sender).transfer(balance);
    }

    function reserveDerp(uint256 numberOfTokens) public onlyOwner {
        require((adminMinted + numberOfTokens) <= adminReserved, "Purchase would exceed reserved supply");

        uint256 supply = totalSupply();
        uint256 i;
        for (i = 0; i < numberOfTokens; i++) {
            if (totalSupply() < MAX_DERP) {
                uint256 mintIndex = supply + i;
                adminMinted++;
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function mint(uint256 numberOfTokens) public payable nonReentrant{
        require(mintIsActive, "Sales are inactive");
        require(numberOfTokens <= derpMaxPerMint, "Cannot purchase this many tokens per transaction");
        uint256 total = totalSupply();
        require((total + numberOfTokens - adminMinted - freeMinted) <= (MAX_DERP - adminReserved - freeReserved), "Purchase would exceed supply");
        require(derpPrice * numberOfTokens <= msg.value, "Incorrect ether value");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            paidMinted++;
            _safeMint(msg.sender, totalSupply());
        }
    }

    function mintFreeClaim(uint256 numberOfTokens) public payable nonReentrant{
        require(mintFreeClaimIsActive, "Sales are inactive");
        require(numberOfTokens <= derpMaxPerMint, "Cannot purchase this many tokens per transaction");
        uint256 total = totalSupply();
        require((total + numberOfTokens - adminMinted - paidMinted) <= (MAX_DERP - adminReserved - paidReserved), "Purchase would exceed supply");
        require((freeClaimMinted[msg.sender] + numberOfTokens) <= freeClaimMaxMint, "Number of tokens requested exceeded the value allowed per wallet");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            if (freeClaimMinted[msg.sender] < freeClaimMaxMint) {
                freeClaimMinted[msg.sender]++;
                freeMinted++;
                _safeMint(msg.sender, totalSupply());
            }
        }
    }
}