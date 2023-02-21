// SPDX-License-Identifier: MIT

/// Collection: DAMN MILKY WAY 
/// Author: e-uphoria by Alessia Moccia (visit https://www.e-uphoria.com/)

/// Powered by ChainLab (https://chainlab.it/)
/// Supervised by lollobene - CTO @ChainLab

////////////////////////////////////////////////////////////
//                             __               _         //
//     ___        __  ______  / /_  ____  _____(_)___ _   //
//    / _ \______/ / / / __ \/ __ \/ __ \/ ___/ / __ `/   //
//   /  __/_____/ /_/ / /_/ / / / / /_/ / /  / / /_/ /    //
//   \___/      \__,_/ .___/_/ /_/\____/_/  /_/\__,_/     //
//                  /_/                                   //
//                                                        //
////////////////////////////////////////////////////////////

pragma solidity 0.8.17;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721Royalty.sol";

contract DAMNMILKYWAY is ERC721Royalty, Ownable {
        
    using Strings for uint256;

    mapping(uint256 => string) private _tokenURIs;
    
    constructor() ERC721("DAMN MILKY WAY", "DMW") {}

    function safeMint(address to, uint256 tokenId, string memory uri) public onlyOwner {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        if (bytes(base).length == 0) {
            return _tokenURI;
        }

        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}