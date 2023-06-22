// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";                                           

contract TheFeastDays is ERC1155Supply, Ownable {

    string collectionURI = "";
    string private name_;
    string private symbol_; 
    uint256 public tokenQty;
    uint256 public currentTokenId;

    constructor() ERC1155(collectionURI) {
        name_ = "The Feast Days";
        symbol_ = "TFD";
        tokenQty = 5;
        currentTokenId = 1;
    }
    
    function name() public view returns (string memory) {
      return name_;
    }

    function symbol() public view returns (string memory) {
      return symbol_;
    }

    //=============================================================================
    // Private Functions
    //=============================================================================

    function privateMint() public onlyOwner {
        _mint(msg.sender, currentTokenId, tokenQty, "");
        currentTokenId++;
    }

    function setCollectionURI(string memory newCollectionURI) public onlyOwner {
        collectionURI = newCollectionURI;
    }

    function getCollectionURI() public view returns(string memory) {
        return collectionURI;
    }

    function setTokenQty(uint256 qty) public onlyOwner {
        tokenQty = qty;
    }

    function setCurrentTokenId(uint256 id) public onlyOwner {
        currentTokenId = id;
    }

    //=============================================================================
    // Override Functions
    //=============================================================================
    
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function uri(uint256 _tokenId) public override view returns (string memory) {
        return string(abi.encodePacked(collectionURI, Strings.toString(_tokenId), ".json"));
    }    
}