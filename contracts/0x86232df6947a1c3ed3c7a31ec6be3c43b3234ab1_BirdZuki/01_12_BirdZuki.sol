// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract BirdZuki is ERC721A, Ownable {
    string  public baseURI;
    uint256 public privateBird;
    uint256 public supplyBird;
    uint256 public maxBird = 101;
    uint256 public giveAway = 10;
    uint256 public price   = 0.004 ether;
    mapping(address => bool) private walletCount;


    constructor() ERC721A("BirdZuki", "BirdZuki", 100) {
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }


    function mint(uint256 count) public payable {
        require(totalSupply() + count < supplyBird, "Excedes maxsupply.");
        require(totalSupply() + 1  > privateBird, "Public sale isnot live yet.");
        require(count < maxBird, "Exceeds max per transaction.");
        require(count > 0, "Must mint at least one token");
        require(count * price == msg.value, "Invalid funds provided.");
         _safeMint(_msgSender(), count);
    }

    function privateMint() public payable {
        require(totalSupply() + 1 <= privateBird, "not available");
        require(!walletCount[msg.sender], " minted already ");
         _safeMint(_msgSender(), 1);
        walletCount[msg.sender] = true;
    }

    function doGiveAway() external onlyOwner {
            _safeMint(_msgSender(), giveAway);
    }
      
    function setSupply(uint256 _newSupplyBird) public onlyOwner {
        supplyBird = _newSupplyBird;
    }

    function setprivateBird(uint256 _newprivateBird) public onlyOwner {
        privateBird = _newprivateBird;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setMax(uint256 _newMax) public onlyOwner {
        maxBird = _newMax;
    }

    function setGiveAway(uint256 _newGA) public onlyOwner {
        giveAway = _newGA;
    }

    
    function withdraw() public onlyOwner {
        require(
        payable(owner()).send(address(this).balance),
        "Withdraw failed"
        );
    }
}