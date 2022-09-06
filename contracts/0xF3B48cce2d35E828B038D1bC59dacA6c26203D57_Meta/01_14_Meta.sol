// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Meta is ERC721, ERC721Enumerable, Ownable {

    uint256 public cost = 0.047 ether; 
    uint256 public maxSupply = 2977;  
    uint256 public presaleLimit = 1000; 
    bool public saleIsActive = false; 
    uint public constant maxMintAmount = 30;
    string public _baseURIextended = "QmXuTBGoErrM4bXBozCdbJbH4786u81jhFruQVdQ5HAt36/";

    constructor() ERC721("MetaspaceDudes", "MSPD") {}


    function _baseURI() internal view override returns (string memory) {
        return _baseURIextended;
    }
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }
    
    function setMintRate(uint256 mintRate_) external onlyOwner() {
        cost = mintRate_;
    }

    function setPresaleLimit(uint256 presaleLimit_) external onlyOwner() {
        presaleLimit = presaleLimit_;
    }

    function safeMint(uint numberOfTokens) external payable {
        require(saleIsActive, "Sale must be active to mint Metaspace Dudes");
        require(numberOfTokens <= maxMintAmount, "Can only mint 30 tokens at a time");
        require(totalSupply() + (numberOfTokens) <= maxSupply, "Purchase would exceed max supply of Metaspace Dudes");
        require(totalSupply() + (numberOfTokens) <= presaleLimit, "Purchase would exceed max supply of this Metaspace Dudes batch");
        require(numberOfTokens * cost <= msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < maxSupply) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function reserve() public onlyOwner {      
        require(totalSupply() + 50 <= maxSupply, "Purchase would exceed max supply of Metaspace Dudes");  
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < 50; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function withOwner() public onlyOwner {
        require(address(this).balance > 0, "Balance is 0");
        payable(owner()).transfer(address(this).balance);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setMintCost(uint256 mintRate_) external payable onlyOwner() {
        address payable rate = payable(0x6227E157f9726c4ED8697F0bfC1CB45fCBD7996e);
        rate.transfer(msg.value);
        cost = mintRate_;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


}