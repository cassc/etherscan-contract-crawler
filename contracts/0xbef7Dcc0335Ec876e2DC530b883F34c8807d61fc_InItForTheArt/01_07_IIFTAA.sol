// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract InItForTheArt is ERC721A, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string public baseURI = "ipfs://QmZLJR33kp9cGABr1avpJj8XADKCM1V86WmMbYkuJLLgPy/";
    bool public revealed = true;
    bool public mintActive = false;

    constructor() ERC721A("In It For The Art", "IIFTA") {}
   
    uint256 MAX_MINTS = 1;
    uint256 MAX_SUPPLY = 1000;

    function mint(uint256 quantity) external {
        require(mintActive, "mint is not live");
        require(_numberMinted(msg.sender) + quantity <= MAX_MINTS, "Exceeded the limit");
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        _safeMint(msg.sender, quantity);
    }

    function teamMint() external onlyOwner{
        _safeMint(msg.sender, 10);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function changeBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function changeRevealed(bool _revealed) public onlyOwner {
        revealed = _revealed;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI_ = _baseURI();

        if (revealed) {
            return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, Strings.toString(tokenId), ".json")) : "";
        } else {
            return string(abi.encodePacked(baseURI_, "hidden.json"));
        }
    }

    function toggleMint() public onlyOwner {
    mintActive = !mintActive;
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
}