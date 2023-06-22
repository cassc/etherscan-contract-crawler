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
import "./IDysToken.sol";

/*
________                  __            _____  .__              
\______ \ ___.__. _______/  |_  ____   /     \ |__| ____  ____  
 |    |  <   |  |/  ___/\   __\/  _ \ /  \ /  \|  |/ ___\/ __ \ 
 |    `   \___  |\___ \  |  | (  <_> )    Y    \  \  \__\  ___/ 
/_______  / ____/____  > |__|  \____/\____|__  /__|\___  >___  >
        \/\/         \/                      \/        \/    \/ 
*/

contract DystoMice is ERC721URIStorage, Ownable{
    using Strings for uint256;
    event MintMice (address indexed sender, uint256 startWith, uint256 times);
    uint256 public totalMice;
    uint256 public totalCount = 3000;
    uint256 public maxBatch = 10;
    uint256 public price = 20000000000000000; // 0.02 eth
    string public baseURI;
    bool private started;
    address public DysToken;
    constructor(string memory name_, string memory symbol_, string memory baseURI_, address tokenAddress) ERC721(name_, symbol_) {
        baseURI = baseURI_;
        DysToken = tokenAddress;
    }
    function setTokenAddress(address token) external onlyOwner() {
        DysToken = token;
    }
    function increaseTotalSupply(uint256 amount) public {
        require(totalMice == totalCount, "need more mints");
        require(amount <= 8000, "too many dummy");
        totalCount = amount;
    }
    function totalSupply() public view virtual returns (uint256) {
        return totalMice;
    }
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }
    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }
    function changePrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }
    function changeBatchSize(uint256 _newBatch) public onlyOwner {
        maxBatch = _newBatch;
    }
    function burnForToken(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
        IDysToken(DysToken).mint(msg.sender);
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");
        
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '.json';
    }
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }
    function setStart(bool _start) public onlyOwner {
        started = _start;
    }
    function devMint(uint256 _times) public onlyOwner {
        emit MintMice(_msgSender(), totalMice+1, _times);
        for(uint256 i=0; i<_times; i++) {
            _mint(_msgSender(), 1 + totalMice++);
        }
    }
    function mintMiceWithToken(uint256 amount) payable public {
        require(totalCount > 3000);
        require(amount >= 5000000000000000000000);
        IDysToken(DysToken).transfer(address(this), amount);
        _mint(_msgSender(), 1 + totalMice++);
    }
    function mintMice(uint256 _times) payable public {
        require(started, "not started");
        require(_times >0 && _times <= maxBatch, "wake wrong number");
        require(totalMice + _times <= totalCount, "wake too much");
        require(msg.value == _times * price, "value error");
        payable(owner()).transfer(msg.value);
        emit MintMice(_msgSender(), totalMice+1, _times);
        for(uint256 i=0; i< _times; i++){
            _mint(_msgSender(), 1 + totalMice++);
        }
    } 
    
}