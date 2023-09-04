// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract Azukid is ERC721A, Ownable {
    string  public              baseURI             ;
    
    uint256 public              sP                  ;
    uint256 public              freeNum             ;
    uint256 public              tXN             = 21;
    uint256 public              price   = 0.02 ether;
    mapping(address => bool) private walletCount;


    constructor() ERC721A("AzuKID DAO", "KIDAZU", 20) {
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }


    function mint(uint256 count) public payable {
        require(totalSupply() + count < sP, "Excedes max supply.");
        require(totalSupply() + 1  > freeNum, "Public sale is not live yet.");
        require(count < tXN, "Exceeds max per transaction.");
        require(count > 0, "Must mint at least one token");
        require(count * price == msg.value, "Invalid funds provided.");
         _safeMint(_msgSender(), count);
    }

    function freeMint() public payable {
        require(totalSupply() + 1 <= freeNum, "Excedes max freemint.");
        require(!walletCount[msg.sender], " 1 free mint per wallet");
         _safeMint(_msgSender(), 1);
        walletCount[msg.sender] = true;
    }

    function airdrop() external onlyOwner {
            _safeMint(_msgSender(), 10);
    }
      
    function setsP(uint256 _newSP) public onlyOwner {
        sP = _newSP;
    }

    function setfN(uint256 _newfN) public onlyOwner {
        freeNum = _newfN;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setTXN(uint256 _newTXN) public onlyOwner {
        tXN = _newTXN;
    }

    
    function withdraw() public onlyOwner {
        require(
        payable(owner()).send(address(this).balance),
        "Withdraw unsuccessful"
        );
    }
}