// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract Renzuki is ERC721A, Ownable {
    string  public baseURI;
    uint256 public maxRenzuki = 3333;
    uint256 public fzuki;
    uint256 public oneTXN = 20;
    uint256 public mdev = 10;
    uint256 public price   = 0.003 ether;
    mapping(address => bool) private walletCount;


    constructor() ERC721A("Renzuki", "Renzuki", 50) {
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }


    function mint(uint256 count) public payable {
    if (totalSupply() + 1  > fzuki)
        {
        require(totalSupply() + count <= maxRenzuki, "sold out");
        require(count <= oneTXN, "Exceeds max per transaction.");
        require(count > 0, "Must mint at least one token");
        require(count * price <= msg.value, "Invalid funds provided.");
         _safeMint(_msgSender(), count);
        }
    else 
        {
        require(!walletCount[msg.sender], " already claimed! ");
        _safeMint(_msgSender(), 1);
        walletCount[msg.sender] = true;
        }

    }

    function mintDev() external onlyOwner {
            _safeMint(_msgSender(), mdev);
    }
      

    function setfreezuki(uint256 _newfzuki) public onlyOwner {
        fzuki = _newfzuki;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setTXN(uint256 _newTXN) public onlyOwner {
        oneTXN = _newTXN;
    }

    function setDev(uint256 _newDev) public onlyOwner {
        mdev = _newDev;
    }

    
    function withdraw() public onlyOwner {
        require(
        payable(owner()).send(address(this).balance),
        "Withdraw failed"
        );
    }
}