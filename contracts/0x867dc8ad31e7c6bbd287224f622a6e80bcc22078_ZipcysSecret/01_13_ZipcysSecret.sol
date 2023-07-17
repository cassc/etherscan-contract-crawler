// SPDX-License-Identifier: MIT

// Contract by pr0xy.io

pragma solidity ^0.8.7;

import './ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract ZipcysSecret is ERC721Enumerable, Ownable {
    string public baseTokenURI;

    constructor() ERC721("ZipcysSecret", "ZS") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function mint(address[] calldata _collectors) external onlyOwner {
        uint supply = totalSupply();

        for(uint i; i < _collectors.length; i++){
            _safeMint( _collectors[i], supply + i );
        }
    }
}