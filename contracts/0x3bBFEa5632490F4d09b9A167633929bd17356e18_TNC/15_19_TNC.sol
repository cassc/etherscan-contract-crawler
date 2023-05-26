// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

contract TNC is ERC721Tradable {  
    
    constructor(address _proxyRegistryAddress) ERC721Tradable("The Nemesis Companions", "TNC", _proxyRegistryAddress){}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://companions.thenemesis.io/api/v1/assets/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://companions.thenemesis.io/api/v1/collection";
    }
}