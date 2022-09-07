// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DOO & CHABBY
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    chubby is the king    //
//                          //
//                          //
//////////////////////////////


contract CHABBY is ERC721Creator {
    constructor() ERC721Creator("DOO & CHABBY", "CHABBY") {}
}