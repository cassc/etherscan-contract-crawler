// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SMS is ERC721A, Ownable {

    string private _baseURIPrefix;
    uint256 private tokenPrice = 70000000000000000; //0.07 ETH
    uint256 private tokenWLPrice = 50000000000000000; //0.05 ETH
    uint256 private constant nftsNumber = 4444;
    bool private isPublicSaleActive = false;
    bool private isWLSaleActive = false;


    mapping(address => bool) public whitelist;
    mapping(address => uint) public claimed;
  
    constructor() ERC721A("Ski Mask Society", "SMS") {}

    function setBaseURI(string memory baseURIPrefix) public onlyOwner {
        _baseURIPrefix = baseURIPrefix;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function flipWLSaleState() public onlyOwner {
        isWLSaleActive = !isWLSaleActive;
    }

    function flipPublicSaleState() public onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function buyTokens(uint amount) public payable {
        require(amount > 0, "Wrong amount");
        require(isPublicSaleActive, "Later");
        require(totalSupply() + amount < nftsNumber, "Sale finished");
        require(tokenPrice * amount <= msg.value, "Need more ETH");
        require(claimed[msg.sender] + amount <= 15, "Tokens done");

        _safeMint(msg.sender, amount);
        claimed[msg.sender] += amount;

    }

    function buyWhite(uint amount) public payable {
        require(amount > 0, "Wrong amount");
        require(isWLSaleActive, "Later");
        require(totalSupply() + amount < nftsNumber, "Sale finished");
        require(tokenWLPrice * amount  <= msg.value, "Need more ETH");
        require(whitelist[msg.sender], "Wrong WL");
        require(claimed[msg.sender] + amount <= 15, "Tokens done");

        _safeMint(msg.sender, amount);
        claimed[msg.sender] += amount;
    }

    function addToWhitelist(address[] memory _address) public onlyOwner {
        for (uint i = 0; i < _address.length; i++) {
            whitelist[_address[i]] = true;
        }
    }

    function setPrice(uint256 _price) external onlyOwner {
        require(_price > 0, "Zero price");
        
        tokenPrice = _price;
    }   

    function directMint(address _address, uint256 amount) public onlyOwner {
        require(totalSupply() + amount < nftsNumber, "Sale finished");

        _safeMint(_address, amount);
    }
}