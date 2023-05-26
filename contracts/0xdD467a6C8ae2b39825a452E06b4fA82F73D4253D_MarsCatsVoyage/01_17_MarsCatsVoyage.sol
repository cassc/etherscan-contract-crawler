//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MarsCatsVoyage is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public MCV_PROVENANCE = "";

    uint public constant maxCatPurchase = 10;
    uint public constant maxCatTokens = 10000;

    bool public saleIsActive = false;

    uint256 public constant catPrice = 50000000000000000; // 0.05 ETH

    constructor(string memory tokenName, string memory symbol) ERC721(tokenName, symbol) {}

    function withdraw() 
        public onlyOwner 
    {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    /*
    * Pause sale if active, make active if paused
    */
    function flipSaleState() 
        public onlyOwner 
    {
        saleIsActive = !saleIsActive;
    }

    /*     
    * Set provenance
    */
    function setProvenanceHash(string memory provenanceHash) 
        public onlyOwner 
    {
        MCV_PROVENANCE = provenanceHash;
    }

    /**
    * Mints Cats
    */
    function mintCat(address sender, uint numberOfTokens, string memory metadataURI)
        public payable
    {
        require(saleIsActive, "Sale must be active to mint Cat");
        require(numberOfTokens <= maxCatPurchase, "Can only mint 10 tokens at a time");
        require(catPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        require(_tokenIds.current().add(numberOfTokens) <= maxCatTokens, "That's all! No more tokens");

        for(uint i = 0; i < numberOfTokens; i++) {
            _tokenIds.increment();

            uint256 id = _tokenIds.current();
            _safeMint(sender, id);
            _setTokenURI(id, metadataURI);
        }
    }

    /*     
    * Set token URI
    */
    function setTokenUri(uint tokenId, string memory metadataURI)
        public onlyOwner
    {
        _setTokenURI(tokenId, metadataURI);
    }
}