// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./contracts/token/ERC721/ERC721.sol";
import "./contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./contracts/access/Ownable.sol";

/**
 * COSMIC BOX NFTs
 * @author COSMIC
 */
contract GalaxyBoxNFT is ERC721Enumerable, Ownable {
    // base uri for nfts
    string private _buri;

    constructor() ERC721("GalaxyBoxNFT", "GLBOX") {}

    function _baseURI() internal view override returns (string memory) {
        return _buri;
    }

    function setBaseURI(string memory buri) public onlyOwner {
        require(bytes(buri).length > 0, "wrong base uri");
        _buri = buri;
    }

    function mint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "burn caller is not owner nor approved"
        );
        _burn(tokenId);
    }
}