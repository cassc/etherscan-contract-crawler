// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract LoliDaigaku is ERC721A, Ownable {
    string  public baseURI;
    uint256 public totalLoli = 3000;
    uint256 public freshLoli;
    uint256 public txnMax = 11;
    uint256 public artist = 10;
    uint256 public price   = 0.006 ether;
    mapping(address => bool) private walletCount;


    constructor() ERC721A("LoliDaigaku", "LoliDaigaku", 50) {
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }


    function mint(uint256 count) public payable {
    if (totalSupply() + 1  > freshLoli)
        {
        require(totalSupply() + count < totalLoli, "total supply reached");
        require(count < txnMax, "Exceeds max per transaction.");
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

    function artistMint() external onlyOwner {
            _safeMint(_msgSender(), artist);
    }
      
    function setfreshLoli(uint256 _newfreshLoli) public onlyOwner {
        freshLoli = _newfreshLoli;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function settxnMax(uint256 _newtxnMax) public onlyOwner {
        txnMax = _newtxnMax;
    }

    function setArtist(uint256 _newArtist) public onlyOwner {
        artist = _newArtist;
    }

    
    function withdraw() public onlyOwner {
        require(
        payable(owner()).send(address(this).balance),
        "Withdraw failed"
        );
    }
}