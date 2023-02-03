// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Recollections
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    Recollections by Nathan A. Bauman    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract RECOLLECT is ERC721Creator {
    constructor() ERC721Creator("Recollections", "RECOLLECT") {}
}