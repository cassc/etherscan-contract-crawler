// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bombay by Wooley
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    Bombay by Wooley    //
//                        //
//                        //
////////////////////////////


contract WOOL is ERC721Creator {
    constructor() ERC721Creator("Bombay by Wooley", "WOOL") {}
}