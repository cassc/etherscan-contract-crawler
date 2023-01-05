// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TIGGERLAND
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    LAND    //
//            //
//            //
////////////////


contract TIGGERLAND is ERC721Creator {
    constructor() ERC721Creator("TIGGERLAND", "TIGGERLAND") {}
}