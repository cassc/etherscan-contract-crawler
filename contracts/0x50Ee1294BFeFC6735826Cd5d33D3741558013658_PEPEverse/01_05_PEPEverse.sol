// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PEPEverse is ERC721A, Ownable {

    string private _baseURIPrefix;
    uint256 private _tokenPrice = 1500000000000000; //0.0015 ETH
    uint256 private _curLimit = 3333;
    uint256 private _curFreeLimit = 2500;
    uint256 private _perWallet = 20;
    uint256 private _perWalletFree = 3;
    bool private _isPublicSaleActive = true;
    bool private _isPublicClaimActive = true;

    mapping(address => uint) public claimed;
    mapping(address => uint) public freeClaimed;
 
    function flipPublicSaleState() public onlyOwner {
        _isPublicSaleActive = !_isPublicSaleActive;
    }

    function flipPublicClaimState() public onlyOwner {
        _isPublicClaimActive = !_isPublicClaimActive;
    }

    function setPrice(uint256 price) public onlyOwner {
        _tokenPrice = price;
    }
    
    function setPerWalletFree(uint256 amount) public onlyOwner {
        _perWalletFree = amount;
    }
       
    function setPerWallet(uint256 amount) public onlyOwner {
        _perWallet = amount;
    }

    function setLimit(uint256 amount) public onlyOwner {
        _curLimit = amount;
    }
    
    function setFreeLimit(uint256 amount) public onlyOwner {
        _curFreeLimit = amount;
    }
  
    function setBaseURI(string memory baseURIPrefix) public onlyOwner {
        _baseURIPrefix = baseURIPrefix;
    }

    constructor() ERC721A("PEPEverse", "PEPEV") {}


    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function buyTokens(uint amount) public payable {
        require(amount > 0, "Wrong amount");
        require(_isPublicSaleActive, "Later");
        require(totalSupply() + amount < _curLimit, "Sale finished");
        require(_tokenPrice * amount <= msg.value, "Need more ETH");
        require(claimed[msg.sender] + amount <= _perWallet, "Tokens done");

        _safeMint(msg.sender, amount);
        claimed[msg.sender] += amount;
    }

    function claim(uint amount) public {
        require(amount > 0, "Wrong amount");
        require(_isPublicClaimActive, "Later");
        require(totalSupply() + amount < _curFreeLimit, "Sale finished");
        require(freeClaimed[msg.sender] + amount <= _perWalletFree, "Tokens done");
        _safeMint(msg.sender, amount);
        freeClaimed[msg.sender] += amount;
    }

    function directMint(address _address, uint256 amount) public onlyOwner {
        require(totalSupply() + amount < _curLimit, "Sale finished");

        _safeMint(_address, amount);
    }

}