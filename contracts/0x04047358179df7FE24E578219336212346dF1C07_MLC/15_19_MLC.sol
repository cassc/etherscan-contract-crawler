// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

contract MLC is ERC721Tradable {  
    
    constructor(address _proxyRegistryAddress) ERC721Tradable("MLF", "MLC", _proxyRegistryAddress){}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://api.marcomontemagno.com/api/v1/000_assets.php?index=";
    }

    function contractURI() public pure returns (string memory) {
        return "https://api.marcomontemagno.com/api/v1/000_collection.php";
    }
}