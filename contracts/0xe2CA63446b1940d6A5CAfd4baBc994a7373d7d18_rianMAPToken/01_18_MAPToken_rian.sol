// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
contract rianMAPToken is ERC721Tradable {
    constructor(address _proxyRegistryAddress) ERC721Tradable("Rian", "MAP", _proxyRegistryAddress){}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://map.j-wave.co.jp/meta/json/rian/1";
    }

}