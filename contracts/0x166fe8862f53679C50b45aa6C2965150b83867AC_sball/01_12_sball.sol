// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract sball is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant maximumSupply = 500000; 
    uint256 public teamMintPrice = 0.1 ether;
    uint256 public publicSalePrice; 
    bool public isPublicSaleActive;
    bool public isRevealed;
    string private _baseTokenURI;

    mapping(address => uint256) public SaleMinted;
    constructor() ERC721A("SBALL", "SBALL") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function SaleMint(uint256 _quantity) external payable callerIsUser {
        require(isPublicSaleActive, "PUBLIC SALE IS NOT ACTIVE");
        require(totalSupply() + _quantity <= maximumSupply, "MAX SUPPLY REACHED" );
        require(msg.value == publicSalePrice * _quantity, "NEED TO SEND CORRECT ETH AMOUNT");

        SaleMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function teamMint(uint256 _quantity) external payable onlyOwner {
        require(totalSupply() + _quantity <= maximumSupply, "MAX SUPPLY REACHED" );
        require(msg.value == teamMintPrice, "NEED TO SEND CORRECT ETH AMOUNT");
        _safeMint(msg.sender, _quantity);
    }



    function setPublicSaleStatus(bool _status) external onlyOwner {
        isPublicSaleActive = _status;
    }

    function setPublicSalePrice(uint256 _price) external onlyOwner {
        publicSalePrice = _price;
    }
    
    
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for non-existent token");
        if (!isRevealed) {
            return _baseTokenURI;
        } else{
            return string(abi.encodePacked(_baseTokenURI, _tokenId.toString()));
        }
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }   

    function setIsRevealed(bool _reveal) external onlyOwner {
        isRevealed = _reveal;
    }   

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
  }
}