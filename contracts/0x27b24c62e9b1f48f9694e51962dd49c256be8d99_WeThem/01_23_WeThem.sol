// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./mixins/ERC721Collection.sol";
import "./mixins/ERC721Presale.sol";
import "./mixins/ERC721Sale.sol";

contract WeThem is ERC721Collection, ERC721Presale, ERC721Sale {
    constructor(string memory name, string memory symbol) 
        ERC721Collection(name, symbol) {}
    
    function _getSaleState() internal view override(ERC721Presale, ERC721Sale) returns(bool) {
        return ERC721Sale._getSaleState();
    }

    function _setPresaleState(bool state) internal override(ERC721Presale, ERC721Sale) {
        return ERC721Presale._setPresaleState(state);
    }
}