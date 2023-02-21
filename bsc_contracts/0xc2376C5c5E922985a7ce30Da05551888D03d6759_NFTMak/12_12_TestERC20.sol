// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMak is ERC721, Ownable {
    
    uint256 private _tokenIds;
    mapping(uint256 => address) private _tokenOwners;
    mapping(uint256 => bytes32) private _tokenHashes;
    
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function _baseURI() override internal view virtual returns (string memory) {
        return "ipfs://bafybeidappnivfdo2jl5o66qiqs2s2x5243g4plyclebzxtm3i6rayeyae/";
    }

    function _generateTokenHash(uint256 tokenId) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(_baseURI(), tokenId, ".jpg"));
    }
    
    // Функция монетизации токена - только владелец контракта может вызывать

    function mint(address to) public onlyOwner returns (uint256) {
        uint256 newItemId = _tokenIds;
        _tokenIds++;
        _safeMint(to, newItemId);
        _tokenOwners[newItemId] = to;
        bytes32 tokenHash = _generateTokenHash(newItemId);
        _tokenHashes[newItemId] = tokenHash;
        return newItemId;
}
    
    // Функция передачи прав собственности на NFT
    function transferToken(address to, uint256 tokenId) onlyOwner public {
        safeTransferFrom(msg.sender, to, tokenId);
    }
    
    // Функция сжигания токена - только владелец контракта может вызывать
    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
        delete _tokenOwners[tokenId];
    }
}