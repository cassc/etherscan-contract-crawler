// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

contract CRY is ERC721Tradable {  
    
    constructor(address _proxyRegistryAddress) ERC721Tradable("CRW", "CRY", _proxyRegistryAddress){}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://api.cryppo.io/assets/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://api.cryppo.io/collection/";
    }
}