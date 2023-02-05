// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

error NFT__ExceededSupply();
error NFT__NonExistentToken();

contract NFTIsERC721A is ERC721A, Ownable {

    uint256 private immutable i_collection_size; 
    string private baseURI;
    using Strings for uint;

    constructor(uint256 _collection_size, string memory _baseURI) ERC721A("Collection Name", "Symbol") {
        i_collection_size = _collection_size;
        baseURI = _baseURI;
    }

    function mint(uint256 quantity) external onlyOwner {
        if(totalSupply() + quantity > i_collection_size) {
            revert NFT__ExceededSupply();
        }
        _mint(msg.sender, quantity);
    }

    function tokenURI(uint _tokenId) public view virtual override(ERC721A) returns (string memory) {
        if(!_exists(_tokenId)) {
            revert NFT__NonExistentToken();
        }

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function getCollectionSize() external view returns(uint256) {
        return i_collection_size;
    }

    function getBaseURI() external view returns(string memory) {
        return baseURI;
    }
}