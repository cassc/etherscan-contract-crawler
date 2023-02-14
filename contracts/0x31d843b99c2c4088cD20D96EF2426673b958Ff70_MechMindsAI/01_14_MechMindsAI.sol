// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
    Intersection of AI and blockchain with 8192 deflationary NFT robots. 
    Chat with your own unique AI companion. 
    Merge MechMinds to make them smarter. 
    FREE Mint.
    
    twitter.com/MechMindsAI
    mechminds.ai
*/

contract MechMindsAI is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_BOTS = 8192;
    uint256 public constant MAX_MINT = 10;
    address private BURN = 0x000000000000000000000000000000000000dEaD;
    uint256 private mg1 = 1;
    uint256 private mg2 = 8193;
    uint256 private mg3 = 12289;
    uint256 private mg4 = 14337;
    uint256 private mg5 = 15361;
    uint256 private mg6 = 15873;
    uint256 private mg7 = 16129;


    bool private _mintIsActive = false;

    string private _metaBaseUri = "https://mechminds.ai/";

    string private _provenance = "";

    constructor() ERC721("MechMinds", "MM") { }

    function mint(uint16 numberOfTokens) public payable {
        require(mintIsActive(), "Mint is not active");
        require(numberOfTokens <= 10, "Can only mint 10 tokens per transaction");
        require(mg1.add(numberOfTokens) <= MAX_BOTS, "Insufficient supply");
        _mintTokens(numberOfTokens);
    }

    function mergeG1(uint256 n1, uint256 n2) public {
        require(1<=n1 && n1<8193, "Not 1st gen");
        require(1<=n2 && n2<8193, "Not 1st gen");
        require(n1 != n2, "Duplicate NFT ID");
        safeTransferFrom(msg.sender, BURN, n1);
        safeTransferFrom(msg.sender, BURN, n2);
        uint256 tokenId = mg2;
        _safeMint(msg.sender, tokenId);
        mg2 = mg2.add(1);
    }

    function mergeG2(uint256 n1, uint256 n2) public {
        require(8193<=n1 && n1<12289, "Not 2nd gen");
        require(8193<=n2 && n2<12289, "Not 2nd gen");
        require(n1 != n2, "Duplicate NFT ID");
        safeTransferFrom(msg.sender, BURN, n1);
        safeTransferFrom(msg.sender, BURN, n2);
        uint256 tokenId = mg3;
        _safeMint(msg.sender, tokenId);
        mg3 = mg3.add(1);
    }

    function mergeG3(uint256 n1, uint256 n2) public {
        require(12289<=n1 && n1<14337, "Not 3rd gen");
        require(12289<=n2 && n2<14337, "Not 3rd gen");
        require(n1 != n2, "Duplicate NFT ID");
        safeTransferFrom(msg.sender, BURN, n1);
        safeTransferFrom(msg.sender, BURN, n2);
        uint256 tokenId = mg4;
        _safeMint(msg.sender, tokenId);
        mg4 = mg4.add(1);
    }

    function mergeG4(uint256 n1, uint256 n2) public {
        require(14337<=n1 && n1<15361, "Not 4th gen");
        require(14337<=n2 && n2<15361, "Not 4th gen");
        require(n1 != n2, "Duplicate NFT ID");
        safeTransferFrom(msg.sender, BURN, n1);
        safeTransferFrom(msg.sender, BURN, n2);
        uint256 tokenId = mg5;
        _safeMint(msg.sender, tokenId);
        mg5 = mg5.add(1);
    }

    function mergeG5(uint256 n1, uint256 n2) public {
        require(15361<=n1 && n1<15873, "Not 5th gen");
        require(15361<=n2 && n2<15873, "Not 5th gen");
        require(n1 != n2, "Duplicate NFT ID");
        safeTransferFrom(msg.sender, BURN, n1);
        safeTransferFrom(msg.sender, BURN, n2);
        uint256 tokenId = mg6;
        _safeMint(msg.sender, tokenId);
        mg6 = mg6.add(1);
    }

    function mergeG6(uint256 n1, uint256 n2) public {
        require(15873<=n1 && n1<16129, "Not 6th gen");
        require(15873<=n2 && n2<16129, "Not 6th gen");
        require(n1 != n2, "Duplicate NFT ID");
        safeTransferFrom(msg.sender, BURN, n1);
        safeTransferFrom(msg.sender, BURN, n2);
        uint256 tokenId = mg7;
        _safeMint(msg.sender, tokenId);
        mg7 = mg7.add(1);
    }

    /* Owner functions */

    /**
     * Reserve a few MechMinds
     */
    function reserve(uint16 numberOfTokens) external onlyOwner {
        require(mg1.add(numberOfTokens) <= MAX_BOTS, "Insufficient supply");
        _mintTokens(numberOfTokens);
    }

    function setMintIsActive(bool active) external onlyOwner {
        _mintIsActive = active;
    }

    function setProvenance(string memory provHash) external onlyOwner {
        _provenance = provHash;
    }

    function setMetaBaseURI(string memory baseURI) external onlyOwner {
        _metaBaseUri = baseURI;
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, 'Insufficient balance');
        payable(msg.sender).transfer(amount);
    }

    function withdrawAll() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /* View functions */
    function mintIsActive() public view returns (bool) {
        return _mintIsActive;
    }

    function provenanceHash() public view returns (string memory) {
        return _provenance;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), uint256(tokenId).toString()));
    }

    /* Internal functions */
    function _mintTokens(uint16 numberOfTokens) internal {
        for (uint16 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = mg1;
            _safeMint(msg.sender, tokenId);
            mg1 = mg1.add(1);
        }
    }

    function _baseURI() override internal view returns (string memory) {
        return _metaBaseUri;
    }
}