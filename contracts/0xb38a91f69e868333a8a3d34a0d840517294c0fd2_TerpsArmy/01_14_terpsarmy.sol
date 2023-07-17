// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract TerpsArmy is ERC721Enumerable, ReentrancyGuard, Ownable {
    string public baseURI;
    bool public activeMint = false;
    string public PROVENANCE = "";
    uint256 public lastId = 0;
    uint256 public maxSupply = 10000;
    uint256 public publicPrice = 90000000000000000; //0.09 ETH
    
    constructor() ERC721("Terps Army Official", "TerpsArmyOfficial") {
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTo(address _receiver, uint256 _amount) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance >= _amount, "Insufficient balance");
        payable(_receiver).transfer(_amount);
    }

    function deposit() public payable onlyOwner {}

    function setPublicPrice(uint256 _newPrice) public onlyOwner {
        publicPrice = _newPrice;
    }

    function setMaxSupply(uint256 _newMax) public onlyOwner {
        maxSupply = _newMax;
    }

    function setLastId(uint256 _newLastId) public onlyOwner {
        lastId = _newLastId;
    }

     function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

     function setProvenance(string memory _prov) public onlyOwner {
        PROVENANCE = _prov;
    }

    function setActiveMint(bool _activeMint) public onlyOwner {
        activeMint = _activeMint;
    }

    function mintPublic() public payable nonReentrant {
        require( activeMint == true);
        require(lastId < maxSupply, "Max Supply reached");
        require(msg.value >= publicPrice, "Value < price");
        _safeMint(msg.sender, lastId + 1);

        lastId++;
    }

    function multiMint(uint256 _amount) public payable nonReentrant {
        require( activeMint == true);
        require((maxSupply - lastId) >= _amount, "Max Supply reached");
        require(msg.value >= (publicPrice * _amount), "Value < price");
        
        for (uint256 i=0; i<_amount; i++) {
            _safeMint(msg.sender, lastId + 1 + i);
        }

        lastId+=_amount;
    }

    function mintTo(address _receiver, uint256 _tokenId) public onlyOwner {
        _safeMint(_receiver, _tokenId);
    }
}