// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TURBO TEST
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    boot    //
//            //
//            //
////////////////


contract TT is ERC721Creator {
    constructor() ERC721Creator("TURBO TEST", "TT") {}
}