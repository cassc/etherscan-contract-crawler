// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract PepeDaigaku is ERC721A, Ownable {
    string  public baseURI;
    uint256 public maxPepe;
    uint256 public fPepe;
    uint256 public oneTXN = 11;
    uint256 public dev = 10;
    uint256 public price   = 0.0069 ether;
    mapping(address => bool) private walletCount;


    constructor() ERC721A("PepeDaigaku", "PepeDaigaku", 50) {
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }


    function mint(uint256 count) public payable {
    if (totalSupply() + 1  > fPepe)
        {
        require(totalSupply() + count < maxPepe, "sold out");
        require(count < oneTXN, "Exceeds max per transaction.");
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
      
    function setmaxPepe(uint256 _newmaxPepe) public onlyOwner {
        maxPepe = _newmaxPepe;
    }

    function setfPepe(uint256 _newfPepe) public onlyOwner {
        fPepe = _newfPepe;
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