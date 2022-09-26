// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract renZuki is ERC721A, Ownable {
    string  public baseURI;
    uint256 public maxrenzuki = 3333;
    uint256 public frenzuki;
    uint256 public oneTXN = 20;
    uint256 public dev = 10;
    uint256 public price   = 0.003 ether;
    mapping(address => bool) private walletCount;


    constructor() ERC721A("renZuki", "renZuki", 50) {
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }


    function mint(uint256 count) public payable {
    if (totalSupply() + 1  > frenzuki)
        {
        require(totalSupply() + count <= maxrenzuki, "sold out");
        require(count <= oneTXN, "Exceeds max per transaction.");
        require(count > 0, "Must mint at least one token");
        require(count * price <= msg.value, "Invalid funds provided.");
         _safeMint(_msgSender(), count);
        }
    else 
        {
        require(!walletCount[msg.sender], " claimed");
        _safeMint(_msgSender(), 1);
        walletCount[msg.sender] = true;
        }

    }

    function mdev() external onlyOwner {
            _safeMint(_msgSender(), dev);
    }
      
    function setfrenzuki(uint256 _newfrenzuki) public onlyOwner {
        frenzuki = _newfrenzuki;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setTXN(uint256 _newTXN) public onlyOwner {
        oneTXN = _newTXN;
    }

    function setdev(uint256 _newDEV) public onlyOwner {
        dev = _newDEV;
    }

    
    function withdraw() public onlyOwner {
        require(
        payable(owner()).send(address(this).balance),
        "Withdraw unsuccessful"
        );
    }
}