// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BULL.AI
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

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


contract BAI is ERC1155Creator {
    constructor() ERC1155Creator("BULL.AI", "BAI") {}
}