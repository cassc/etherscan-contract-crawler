// SPDX-License-Identifier: MIT

pragma solidity >0.6.6;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

// CakeToken with Governance.
contract MockNFT is ERC721 {


    constructor (string memory baseURI_, string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        _setBaseURI(baseURI_); 
    }

    function mint(address _to, uint256 _num) external {
        for (uint i = 0; i < _num; i ++) {
            _mint(_to, ERC721.totalSupply() + 1);
        }
    }

    function setBaseURI(string memory baseURI_) external {
        _setBaseURI(baseURI_);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory uri = super.tokenURI(tokenId);
        return string(abi.encodePacked(uri, ".json"));
    }
}