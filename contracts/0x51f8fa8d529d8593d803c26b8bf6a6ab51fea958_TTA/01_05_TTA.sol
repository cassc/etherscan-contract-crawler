// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Through The Ages
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    #### ##  #### ##    ##         //
//    # ## ##  # ## ##     ##        //
//      ##       ##      ## ##       //
//      ##       ##      ##  ##      //
//      ##       ##      ## ###      //
//      ##       ##      ##  ##      //
//     ####     ####    ###  ##      //
//                                   //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract TTA is ERC721Creator {
    constructor() ERC721Creator("Through The Ages", "TTA") {}
}