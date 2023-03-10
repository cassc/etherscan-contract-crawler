// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pundits
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Pundits          //
//    April 29 2013    //
//                     //
//                     //
/////////////////////////


contract NLR is ERC721Creator {
    constructor() ERC721Creator("Pundits", "NLR") {}
}