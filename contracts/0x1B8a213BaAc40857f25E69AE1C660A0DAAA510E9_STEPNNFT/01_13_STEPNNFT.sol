// contracts/STEPNNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * STEPN NFTs
 * @author STEPN
 */
contract STEPNNFT is ERC721Enumerable, Ownable {
    // base uri for nfts
    string private _buri;
    address private _deployer = _msgSender();

    constructor() ERC721("STEPNNFT", "SNFT") {}

    function _baseURI() internal view override returns (string memory) {
        return _buri;
    }

    function setBaseURI(string memory buri) public {
        require(bytes(buri).length > 0, "wrong base uri");
        require(_deployer == _msgSender(), "wrong contract deployer");
        _buri = buri;
    }

    function mint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function multimint(address to, uint[] memory tokenId) public onlyOwner {
        for (uint i = 0; i < tokenId.length; i++){
            _safeMint(to, tokenId[i]);
    }
  }

    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "burn caller is not owner nor approved"
        );
        _burn(tokenId);
    }
}