// SPDX-License-Identifier: MIT

pragma solidity >0.6.6;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

// CakeToken with Governance.
contract MockNFT is ERC721 {


    constructor (string memory baseURI_, string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        _setBaseURI(baseURI_); 
    }

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external {
        _setTokenURI(tokenId, _tokenURI);
    }

    function setBaseURI(string memory baseURI_) external {
        _setBaseURI(baseURI_);
    }

    function safeMint(address to, uint256 tokenId, bytes memory _data) external {
        _safeMint(to, tokenId, _data);
    }

    function multiMint(address[] memory tos, uint256[] memory tokenIds, bytes memory _data) external {
        if (false) {
            _data;
        }
        require(tos.length == tokenIds.length, "illegal length");
        for (uint i = 0; i < tos.length; i ++) {
            _mint(tos[i], tokenIds[i]);
        }
    }

    function multiSafeMint(address[] memory tos, uint256[] memory tokenIds, bytes memory _data) external {
        require(tos.length == tokenIds.length, "illegal length");
        for (uint i = 0; i < tos.length; i ++) {
            _safeMint(tos[i], tokenIds[i], _data);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory uri = super.tokenURI(tokenId);
        return string(abi.encodePacked(uri, ".json"));
    }
}