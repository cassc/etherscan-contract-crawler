// SPDX-License-Identifier: MIT
/*

██╗██████╗░░██████╗░░█████╗░███████╗
██║██╔══██╗██╔════╝░██╔══██╗██╔════╝
██║██║░░██║██║░░██╗░███████║█████╗░░
██║██║░░██║██║░░╚██╗██╔══██║██╔══╝░░
██║██████╔╝╚██████╔╝██║░░██║██║░░░░░
╚═╝╚═════╝░░╚═════╝░╚═╝░░╚═╝╚═╝░░░░░
*/

pragma solidity >=0.8.17 <0.9.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";


contract IDGAF is Ownable, ERC721A, ReentrancyGuard {

    string private baseURI;
    bool public revealed = false;
    bool public paused = false;
    uint256 public cost = 0.01 ether;
     uint256 maxBatchSize = 20000;
     uint256 collectionSize = 20000;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC721A(_name, _symbol) {
        baseURI = _uri;
        
    }

    modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function LETSMOON(uint256 _mintAmount) public payable callerIsUser  {
        uint256 supply = totalSupply();
        uint256 actualCost = cost;
        require(!paused);
        require(_mintAmount > 0, "mint amount > 0");
        require(supply + _mintAmount <= collectionSize, "max NFT limit exceeded");
        if (msg.sender != owner()) {
            require(_mintAmount <= maxBatchSize, "max mint amount exceeded");
            require(msg.value >= actualCost * _mintAmount, "insufficient funds");
        }
        _safeMint(msg.sender, _mintAmount);
    }
     
    function LFGG(uint256 _mintAmount, address destination) public onlyOwner  {
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "mint amount > 0");
        require(_mintAmount <= maxBatchSize, "max mint amount exceeded");
        require(supply + _mintAmount <= collectionSize, "max NFT limit exceeded");
        _safeMint(destination, _mintAmount);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory) {
        if (!revealed) {
            return baseURI;
        } else {
            string memory uri = super.tokenURI(tokenId);
            return uri;
        }
    }

    function getContractBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
    }


    function setReveal(bool _reveal) public onlyOwner {
        revealed = _reveal;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

 
    function withdraw() public payable onlyOwner nonReentrant{
        (bool os,) = payable(msg.sender).call{value : address(this).balance}("");
        require(os, "WITHDRAW ERROR");
    }
    
    function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }
    
    function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return _ownershipOf(tokenId);
  }

   

}