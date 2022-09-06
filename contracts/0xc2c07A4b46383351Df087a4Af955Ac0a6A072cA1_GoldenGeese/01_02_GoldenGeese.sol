// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./TokenSet.sol";

contract GoldenGeese is TokenSet {

    /**
     * Unordered List
     */
    constructor(
        address _registry,
        uint16 _traitId
        ) 
        TokenSet (
            "Golden Goose Trait",
            _registry,
            _traitId
        ) {
    }

}