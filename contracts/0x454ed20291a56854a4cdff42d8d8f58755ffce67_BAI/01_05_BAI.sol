// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BULL.AI
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//     _           _ _     //
//    | |         | | |    //
//    | |__  _   _| | |    //
//    | '_ \| | | | | |    //
//    | |_) | |_| | | |    //
//    |_.__/ \__,_|_|_|    //
//                         //
//                         //
/////////////////////////////


contract BAI is ERC721Creator {
    constructor() ERC721Creator("BULL.AI", "BAI") {}
}