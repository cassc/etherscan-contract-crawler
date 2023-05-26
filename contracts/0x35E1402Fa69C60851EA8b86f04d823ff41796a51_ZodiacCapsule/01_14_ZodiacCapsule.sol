// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ZodiacCapsule is ERC721, ERC721URIStorage, Ownable {
    using Strings for uint256;
    
    IERC721Enumerable public collection = IERC721Enumerable(0xfcB1315C4273954F74Cb16D5b663DBF479EEC62e);
    string private _tokenBaseURI;
    
    constructor() ERC721("ZodiacCapsule", "ZODIACCAPSULE") {}
    
    function _baseURI() internal override view returns (string memory) {
        return _tokenBaseURI;
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _tokenBaseURI = baseURI;
    }

    function claim(uint256[] calldata tokenIds) public {
        for(uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            
            require(collection.ownerOf(tokenId) == msg.sender, "You must own the corresponding NFT to mint this.");
        }
        
        // Use two loops to prevent safemint call if a token id later in the flow is incorrect. Saves the claimer gas if they made a mistake
        
        for(uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            _safeMint(msg.sender, tokenId);
        }
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        string memory baseURI = _baseURI();
        
        if (bytes(baseURI).length > 0) {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }
        
        return "";
    }
}