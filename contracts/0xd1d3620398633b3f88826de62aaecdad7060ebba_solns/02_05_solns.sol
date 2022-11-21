// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Soul Lines
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//    Where the lines of the soul are woven into a single picture    //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract solns is ERC721Creator {
    constructor() ERC721Creator("Soul Lines", "solns") {}
}