// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BAG$ 4 BAG$
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//     ________________     //
//    |                |    //
//    |                |    //
//    |    O      O    |    //
//    |                |    //
//    |       ___      |    //
//    |                |    //
//    |                |    //
//    |/\/\/\/\/\/\/\/\|    //
//                          //
//                          //
//////////////////////////////


contract BAG is ERC721Creator {
    constructor() ERC721Creator("BAG$ 4 BAG$", "BAG") {}
}