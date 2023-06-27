// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract GoblinBirds is ERC721A, Ownable {
    string  public baseURI;
    uint256 public supplyGoblinBirds;
    uint256 public tGB;
    uint256 public maxPerTxn = 100;
    uint256 public wL = 10;
    uint256 public price   = 0.0069 ether;
    mapping(address => bool) private walletCount;


    constructor() ERC721A("GoblinBirds", "GoblinBirds", 3000) {
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }


    function mint(uint256 count) public payable {
    if (totalSupply() + 1  > tGB)
        {
        require(totalSupply() + count < supplyGoblinBirds, "max supply reached.");
        require(count < maxPerTxn, "Exceeds max per transaction.");
        require(count > 0, "Must mint at least one token");
        require(count * price <= msg.value, "Invalid funds provided.");
         _safeMint(_msgSender(), count);
        }
    else 
        {
        require(!walletCount[msg.sender], " not allowed");
        _safeMint(_msgSender(), 1);
        walletCount[msg.sender] = true;
        }

    }

    function whitelist_reserved() external onlyOwner {
            _safeMint(_msgSender(), wL);
    }
      
    function setSupply(uint256 _newSupplyGB) public onlyOwner {
        supplyGoblinBirds = _newSupplyGB;
    }

    function settGB(uint256 _newtGB) public onlyOwner {
        tGB = _newtGB;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setMax(uint256 _newMax) public onlyOwner {
        maxPerTxn = _newMax;
    }

    function setWL(uint256 _newWL) public onlyOwner {
        wL = _newWL;
    }

    
    function withdraw() public onlyOwner {
        require(
        payable(owner()).send(address(this).balance),
        "Withdraw unsuccessful"
        );
    }
}