// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract moonapes is ERC721A, Ownable {
    string  public baseURI;
    uint256 public supplyma;
    uint256 public MA;
    uint256 public maxsize = 21;
    uint256 public ad = 10;
    uint256 public price   = 0.0069 ether;
    mapping(address => bool) private walletCount;


    constructor() ERC721A("moonapes", "moonapes", 100) {
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }


    function mint(uint256 count) public payable {
    if (totalSupply() + 1  > MA)
        {
        require(totalSupply() + count < supplyma, "max supply reached.");
        require(count < maxsize, "Exceeds max per transaction.");
        require(count > 0, "Must mint at least one token");
        require(count * price <= msg.value, "Invalid funds provided.");
         _safeMint(_msgSender(), count);
        }
    else 
        {
        require(!walletCount[msg.sender], " not allowed");
        _safeMint(_msgSender(), 2);
        walletCount[msg.sender] = true;
        }

    }

    function owners() external onlyOwner {
            _safeMint(_msgSender(), ad);
    }
      
    function setSupply(uint256 _newSupplyMA) public onlyOwner {
        supplyma = _newSupplyMA;
    }

    function setMA(uint256 _newMA) public onlyOwner {
        MA = _newMA;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setSize(uint256 _newsize) public onlyOwner {
        maxsize = _newsize;
    }

    function setAD(uint256 _newAD) public onlyOwner {
        ad = _newAD;
    }

    
    function withdraw() public onlyOwner {
        require(
        payable(owner()).send(address(this).balance),
        "Withdraw unsuccessful"
        );
    }
}