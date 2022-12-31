// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HYPEEAST
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    $HYPEEAST    //
//                 //
//                 //
/////////////////////


contract HYPEEAST is ERC721Creator {
    constructor() ERC721Creator("HYPEEAST", "HYPEEAST") {}
}