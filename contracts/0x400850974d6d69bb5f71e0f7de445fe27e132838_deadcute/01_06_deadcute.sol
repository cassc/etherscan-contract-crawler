/*                                                                                                                                

:::::::-.  .,::::::   :::.   :::::::-.      .,-:::::  ...    :::::::::::::::.,::::::  
 ;;,   `';,;;;;''''   ;;`;;   ;;,   `';,  ,;;;'````'  ;;     ;;;;;;;;;;;'''';;;;''''  
 `[[     [[ [[cccc   ,[[ '[[, `[[     [[  [[[        [['     [[[     [[      [[cccc   
  $$,    $$ $$""""  c$$$cc$$$c $$,    $$  $$$        $$      $$$     $$      $$""""   
  888_,o8P' 888oo,__ 888   888,888_,o8P'  `88bo,__,o,88    .d888     88,     888oo,__ 
  MMMMP"`   """"YUMMMYMM   ""` MMMMP"`      "YUMMMMMP""YmmMMMM""     MMM     """"YUMMM

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

contract deadcute is ERC721A, Ownable, ReentrancyGuard {

    // Variables
    string private _baseTokenURI;
    string private _notRevealedURI;
    uint256 public maxTokens = 10000;
    uint256 public tokenReserve = 500;
    bool public publicMintActive = false;
    bool public revealed = false;
    uint256 public maxTokenMint = 5;

    constructor() ERC721A("Dead Cute Sugar Skulls", "SKULLS") {}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (revealed == false) {
            return _notRevealedURI;
        }

        string memory _tokenURI = super.tokenURI(tokenId);
        return
            bytes(_tokenURI).length > 0
                ? string(abi.encodePacked(_tokenURI, ".json")): "";
    }

    // It's a free mint, so we're reserving some for giveaways and the team!
    function reserveTokens(address _to, uint256 _reserveAmount) external onlyOwner {        
        require(_reserveAmount <= tokenReserve, "Not enough reserve left to mint that quantity");
        require(totalSupply() + _reserveAmount <= maxTokens, "Exceeds max supply");
        _safeMint(_to, _reserveAmount);
        tokenReserve -= _reserveAmount;
    }

    function publicMint(uint _numberOfTokens) external nonReentrant {
        require(publicMintActive, "Do not be impatient");
        require(msg.sender == tx.origin, "Caller cannot be contract");
        require(_numberOfTokens <= maxTokenMint, "Do not be greedy");
        require(totalSupply() + _numberOfTokens <= maxTokens - tokenReserve, "Exceeds max supply");
        _safeMint(msg.sender, _numberOfTokens);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function notRevealedURI() external view returns (string memory) {
        return _notRevealedURI;
    }

    function setNotRevealedURI(string memory _newURI) external onlyOwner {
        _notRevealedURI = _newURI;
    }

    function toggleReveal() external onlyOwner {
        revealed = !revealed;
    }

    function togglePublicMint() external onlyOwner {
        publicMintActive = !publicMintActive;
    }

    function setMaxTokenMint(uint256 _newMaxTokenMint) external onlyOwner {
        maxTokenMint = _newMaxTokenMint;
    }

    function setTokenReserve(uint256 _newTokenReserve) external onlyOwner {
        tokenReserve = _newTokenReserve;
    }

    function remainingSupply() external view returns (uint256) {
        return maxTokens - totalSupply();
    }

    function lowerMaxSupply(uint256 _newMax) external onlyOwner {
        require(_newMax < maxTokens, "Can only lower supply");
        require(maxTokens > totalSupply(), "Can't set below current");
        maxTokens = _newMax;
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        payable(msg.sender).transfer(address(this).balance);
    }

}