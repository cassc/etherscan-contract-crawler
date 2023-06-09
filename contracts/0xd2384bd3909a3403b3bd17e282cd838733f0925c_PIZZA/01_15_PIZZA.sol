// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./ERC721.sol"; 
import "./openzeppelin/contracts/access/Ownable.sol";
// import "hardhat/console.sol";

/**
 * @title PIZZA contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract PIZZA is ERC721, Ownable {
    uint256 public constant singleMaxMint = 10;
    uint256 public MAX_PIZZA;
    bool public saleIsActive = false;
    uint256 private COMMON_INIT_TOKENID = 0;
    
    constructor(
        string memory name,
        string memory symbol,
        uint256 maxNftSupply
    ) ERC721(name, symbol) {
        MAX_PIZZA = maxNftSupply;
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI)
        public
        onlyOwner
    {
        _setTokenURI(tokenId, tokenURI);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function setMAX_PIZZA(uint256 amount) public onlyOwner {
        MAX_PIZZA = amount;
    }

    /*
     * Pause sale if active, make active if paused
     */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    

    function mint(address user,uint256 numberOfTokens) public onlyOwner {
        require(saleIsActive, "Sale must be active to mint pizza");
        require(
            numberOfTokens <= singleMaxMint,
            "Can only mint 20 tokens at a time"
        );
        require(
            totalSupply() + numberOfTokens <= MAX_PIZZA,
            "Purchase would exceed max supply of pizza"
        );
        for (uint256 i = 0; i < numberOfTokens; i++) {
            if (totalSupply() < MAX_PIZZA) {
                _safeMint(user, COMMON_INIT_TOKENID);
            }
            COMMON_INIT_TOKENID++;
        }
    }

    function getTokenIdsByAddress(address owner)public view returns (uint256[] memory){
        return _getTokenIdsByAddress(owner);
    }

    function refuseTransfer(uint256[] calldata tokenIds)public onlyOwner returns(bool){
        require(tokenIds.length <= 20,"Can only input 20 tokenIds");
        return _refuseTransfer(tokenIds);
    }

    function isRefuseTransfer(uint256[] calldata tokenIds)public view returns(bool[] memory){
        require(tokenIds.length <= 20,"Can only input 20 tokenIds");
        return _isRefuseTransfer(tokenIds);
    }
}