// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MultiD is ERC721A, Ownable {
    using SafeMath for uint256;
    
    uint256 private _multiDPrice = 0.15 ether;
    string private _URI;
    bool private _isRevealURI = false;
    string private _preRevealURI = "https://multid.rndity.com/0?";

    bool public saleIsActive = false;
    uint public constant maxMintPurchase = 3;
    uint256 public constant maxMultiD = 12345;

    constructor() ERC721A("Kleks Academy multi-D NFT", "multiDNFT") {
    }

    function withdraw()
        public
        onlyOwner
    {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setPrice(uint256 _newPrice)
        public
        onlyOwner()
    {
        _multiDPrice = _newPrice * 1 ether;
    }

    function getPrice()
        public
        view
        returns (uint256)
    {
        return _multiDPrice;
    }

    function mintMultiD(uint numberOfTokens)
        public
        payable
    {
        uint256 totalSupply = totalSupply();
        require(saleIsActive, "Sale must be active to mint multi-D NFT");
        require(numberOfTokens <= maxMintPurchase, "Can only mint 3 multi-D NFT at a time");
        require(totalSupply.add(numberOfTokens) <= maxMultiD, "Purchase would exceed max supply of multi-D NFT");
        require(_multiDPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        _safeMint(msg.sender, numberOfTokens);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_isRevealURI) {
            return _preRevealURI;
        }

        return super.tokenURI(tokenId);
    }

    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return _URI;
    }

    function setBaseURI(string memory newBaseURI)
        public
        onlyOwner
    {
        _isRevealURI = true;
        _URI = newBaseURI;
    }

    function flipRevealState()
        public
        onlyOwner
    {
        _isRevealURI = !_isRevealURI;
    }

    function flipSaleState()
        public
        onlyOwner
    {
        saleIsActive = !saleIsActive;
    }
}