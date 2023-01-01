// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AFRO X
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    AFRO X    //
//              //
//              //
//////////////////


contract AFROX is ERC721Creator {
    constructor() ERC721Creator("AFRO X", "AFROX") {}
}