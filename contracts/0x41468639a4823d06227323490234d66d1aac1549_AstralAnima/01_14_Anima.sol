// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Journey {
    function getNumberRealms(address _player) public view returns (uint256) {}
}

contract AstralAnima is ERC721Enumerable, ReentrancyGuard, Ownable {
    string public baseURI;
    Journey _journey;

    
    string public PROVENANCE = "";
    uint256 public lastId = 0;
    uint256 public maxSupply = 700;
    uint256 public discountPrice = 70000000000000000; // in wei, 0.07 ETH 
    uint256 public publicPrice = 150000000000000000; //0.15 ETH
    
    mapping(address=>bool) public lordsDiscountCollected;

    constructor(address _journeyAddr) ERC721("Astral Anima", "AstralAnima") {
        _journey = Journey(_journeyAddr);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function deposit() public payable onlyOwner {}

    function setDiscountPrice(uint256 _discountPrice) public onlyOwner {
        discountPrice = _discountPrice;
    }

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

    function mintFromJourney() public payable nonReentrant {
        require(lastId < maxSupply, "Anima: Max Supply reached");
        require(_journey.getNumberRealms(msg.sender) > 0, "Anima: No realms");
        require(msg.value >= discountPrice, "Anima: Value < price");
        require(!lordsDiscountCollected[msg.sender], "Anima: Already collected");
        _safeMint(msg.sender, lastId + 1);
        lordsDiscountCollected[msg.sender] = true;

        lastId++;
    }

    function mintPublic() public payable nonReentrant {
        require(lastId < maxSupply, "Anima: Max Supply reached");
        require(msg.value >= publicPrice, "Anima: Value < price");
        _safeMint(msg.sender, lastId + 1);

        lastId++;
    }

    function multiMint(uint256 _amount) public payable nonReentrant {
        require((maxSupply - lastId) >= _amount, "Anima: Max Supply reached");
        require(msg.value >= (publicPrice * _amount), "Anima: Value < price");
        
        for (uint256 i=0; i<_amount; i++) {
            _safeMint(msg.sender, lastId + 1 + i);
        }

        lastId+=_amount;
    }

    function mintTo(address _receiver, uint256 _tokenId) public onlyOwner {
        _safeMint(_receiver, _tokenId);
    }
}