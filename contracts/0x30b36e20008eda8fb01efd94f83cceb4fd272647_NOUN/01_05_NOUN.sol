// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sebastien's Noundry
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    ⌐◨-◨    //
//            //
//            //
////////////////


contract NOUN is ERC721Creator {
    constructor() ERC721Creator("Sebastien's Noundry", "NOUN") {}
}