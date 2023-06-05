// SPDX-License-Identifier: MIT

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//                                                         //
//                                                         //
//        __               __          __    _ __          //
//       / /_  ____ ______/ /_  ____  / /_  (_/ /______    //
//      / __ \/ __ `/ ___/ __ \/ __ \/ __ \/ / __/ ___/    //
//     / /_/ / /_/ (__  / / / / /_/ / /_/ / / /_(__  )     //
//    /_____/\____/____/_/ /_/\____/_____/_/\__/____/      //
//                                                         //
//                                                         //
//                                                         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////

pragma solidity ^0.8.4;

import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/utils/Counters.sol";

contract XenomorphChaos is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("XenomorphChaos", "XENO") {}

    function safeMint(address to, string memory uri, string memory imageuri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _setImageURI(tokenId, imageuri);
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
        return super.tokenURI(tokenId);
    }

    // Including Individual Image Hash Onchain
    mapping(uint256 => string) private _imageURIs;

    function imageURI(uint256 tokenId) public view virtual returns (string memory) {
        _requireMinted(tokenId);

        string memory _imageURI = _imageURIs[tokenId];
        return _imageURI;
    }

    function _setImageURI(uint256 tokenId, string memory _imageURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _imageURIs[tokenId] = _imageURI;
    }

}