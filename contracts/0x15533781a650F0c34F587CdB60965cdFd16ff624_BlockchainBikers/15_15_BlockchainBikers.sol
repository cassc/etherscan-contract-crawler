// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BlockchainBikers contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */

contract BlockchainBikers is ERC721, Ownable {
    using SafeMath for uint256;

    string public BIKER_PROVENANCE = "";
    uint256 public constant bikerPrice = 90000000000000000; // 0.09 ETH
    uint public constant maxBikerPurchase = 20;
    uint public constant reservedBikers = 20;
    uint256 public constant maxBikers = 11111;
    bool public saleIsActive = false;

    constructor() ERC721("BlockchainBikers", "BIKERS") {
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

   function reserveBikers() public onlyOwner {
        uint mintIndex = totalSupply();
        uint i;
        for (i = 0; i < reservedBikers; i++) {
            _safeMint(msg.sender, mintIndex + i);
        }
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        BIKER_PROVENANCE = provenanceHash;
    }

    function mintBikers(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale is not active so you cannot mint.");
        require(numberOfTokens <= maxBikerPurchase, "Sorry but you can only mint 20 Bikers per transaction!");
        require(totalSupply().add(numberOfTokens) <= maxBikers, "Not enough Bikers left to mint that amount! Everybody panic!");
        require(bikerPrice.mul(numberOfTokens) <= msg.value, "You sent the wrong amount of ETH, Bad Biker.");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < maxBikers) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }
}