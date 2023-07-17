/**
 *Submitted for verification at Etherscan.io on 2021-08-08
*/
// Sources flattened with hardhat v2.5.0 https://hardhat.org
// SPDX-License-Identifier: MIT
// File contracts/BMWU/bmwu.sol
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
1. we want people to be able to burn their dystomice to mint a spacemouse 
    -- in order to do this, this contract must be able to accept an ERC721 token as an input. 
    -- for whatever reason you need to implement the 'IERC721Receiver.sol' for the contract to be able to handle ERC721 token transfers.
*/

contract SpaceMice is ERC721URIStorage, Ownable{
    using Strings for uint256;
    event MintMice (address indexed sender, uint256 startWith, uint256 times);
    uint256 public TOTALMICE;
    uint256 public TOTALCOUNT = 999;
    uint256 public MAXBATCH = 1;
    uint256 public deezPrice = 10000000000000000000000; // 10,000 DEEZ / mint
    string public BASEURI;
    bool private STARTED;
    address public DEEZTOKEN;

    constructor(string memory name_, string memory symbol_, string memory BASEURI_, address tokenAddress) ERC721(name_, symbol_) {
        BASEURI = BASEURI_;
        DEEZTOKEN = tokenAddress;
    }
    function totalSupply() public view virtual returns (uint256) {
        return TOTALMICE;
    }
    function _baseURI() internal view virtual override returns (string memory){
        return BASEURI;
    }
    function setBASEURI(string memory _newURI) public onlyOwner {
        BASEURI = _newURI;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");
        
        string memory BASEURI = _baseURI();
        return bytes(BASEURI).length > 0
            ? string(abi.encodePacked(BASEURI, tokenId.toString(), ".json")) : '.json';
    }
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }
    function setStart(bool _start) public onlyOwner {
        STARTED = _start;
    }

    function currentDeezCost() public view returns (uint256) {

        if (TOTALMICE <= 200) return 5000000000000000000000;
        if (TOTALMICE > 200 && TOTALMICE <= 400)
            return 10000000000000000000000;
        if (TOTALMICE > 400 && TOTALMICE <= 600)
            return 15000000000000000000000;
        if (TOTALMICE > 600 && TOTALMICE <= 800)
            return 20000000000000000000000;
        if (TOTALMICE > 800 && TOTALMICE <= 999)
            return 25000000000000000000000;

        revert();
    }

    function mintMiceWithDeez(uint256 amount) public {
        require(STARTED, "not STARTED");
        require(amount >= currentDeezCost(), "not enough deez!");
        require(TOTALMICE + 1 <= TOTALCOUNT, "not enough mice!");
        IERC20(DEEZTOKEN).transferFrom(msg.sender, address(this), currentDeezCost());
        emit MintMice(_msgSender(), TOTALMICE+1, 1);
        _mint(_msgSender(), 1 + TOTALMICE++);
    }    
}