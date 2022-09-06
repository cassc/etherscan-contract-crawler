// SPDX-License-Identifier: MIT

///////////////////////////////////////////////////////////////////////////////////////
//      ____                 __               ___           __           _ __        //
//     / __ \__ _____ ____  / /___ ____ _    / _ \___  ____/ /________ _(_) /____    //
//    / /_/ / // / _ `/ _ \/ __/ // /  ' \  / ___/ _ \/ __/ __/ __/ _ `/ / __(_-<    //
//    \___\_\_,_/\_,_/_//_/\__/\_,_/_/_/_/ /_/   \___/_/  \__/_/  \_,_/_/\__/___/    //
//       ___  _         __            _   __             ___                         //
//      / _ \(_)__  ___/ /__ _____   | | / /__ ____     / _ | ______ _  ___ ____     //
//     / ___/ / _ \/ _  / _ `/ __/   | |/ / _ `/ _ \   / __ |/ __/  ' \/ _ `/ _ \    //
//    /_/  /_/_//_/\_,_/\_,_/_/      |___/\_,_/_//_/  /_/ |_/_/ /_/_/_/\_,_/_//_/    //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.4;

import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/utils/Counters.sol";

contract QuantumPortraits is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("QuantumPortraits", "QPT") {}

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