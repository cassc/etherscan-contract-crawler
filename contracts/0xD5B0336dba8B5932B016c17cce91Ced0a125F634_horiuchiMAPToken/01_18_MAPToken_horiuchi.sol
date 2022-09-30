// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
contract horiuchiMAPToken is ERC721Tradable {
    constructor(address _proxyRegistryAddress) ERC721Tradable("Hiroyuki_Horiuchi", "MAP", _proxyRegistryAddress){}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://map.j-wave.co.jp/meta/json/horiuchi/1";
    }

}