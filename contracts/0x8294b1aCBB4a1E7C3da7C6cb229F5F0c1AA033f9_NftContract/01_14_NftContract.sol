//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract NftContract is Ownable, ERC721Enumerable{

    constructor (string memory name, string memory symbol) ERC721(name, symbol) {}
    mapping(uint=>tokenMetadata) public metadataMap;
    struct tokenMetadata{
        string tokenName;
        string ipfsContentHash;
        string ipfsPictureHash;
        string ipfsSnippetHash;
        string description;
    }

    struct tokenInfo{
        uint256 id;
        address owner;
        string tokenName;
        string ipfsContentHash;
        string ipfsPictureHash;
        string ipfsSnippetHash;
        string description;
    }

    function mintToken(tokenInfo memory info) onlyOwner public {
        _safeMint(info.owner, info.id);
        tokenMetadata memory meta = tokenMetadata(info.tokenName, info.ipfsContentHash, info.ipfsPictureHash, info.ipfsSnippetHash, info.description);
        metadataMap[info.id] = meta;
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
    }

    function getTokenMetaByPublicKey(address publicKey) public view returns (tokenInfo[] memory){
        uint amount = balanceOf(publicKey);
        tokenInfo[] memory result = new tokenInfo[](amount);
        for (uint j = 0; j < amount; j++){
            uint256 tokenId = tokenOfOwnerByIndex(publicKey, j);
            tokenInfo memory tokenData = getTokenMeta(tokenId);
            result[j] = tokenData;
        }
        return (result);
    }

    function getTokenMeta(uint256 tokenId) public view returns (tokenInfo memory){
        tokenMetadata memory metadata = metadataMap[tokenId];
        return (tokenInfo(tokenId, ownerOf(tokenId), metadata.tokenName, metadata.ipfsContentHash, metadata.ipfsPictureHash, metadata.ipfsSnippetHash, metadata.description));
    }
}