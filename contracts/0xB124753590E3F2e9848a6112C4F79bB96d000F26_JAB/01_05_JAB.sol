// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JerrY Alpha Badge
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    JerrY Alpha Badge for OGs    //
//                                 //
//                                 //
/////////////////////////////////////


contract JAB is ERC721Creator {
    constructor() ERC721Creator("JerrY Alpha Badge", "JAB") {}
}