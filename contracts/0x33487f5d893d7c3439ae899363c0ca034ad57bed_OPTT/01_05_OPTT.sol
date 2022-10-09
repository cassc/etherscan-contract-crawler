// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OPTTAG Team
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    We are OPTTAG.    //
//                      //
//                      //
//////////////////////////


contract OPTT is ERC721Creator {
    constructor() ERC721Creator("OPTTAG Team", "OPTT") {}
}