// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: #1 crush open edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    ,         ,    //
//    |\\\\ ////|    //
//    | \\\V/// |    //
//    |  |~~~|  |    //
//    |  |===|  |    //
//    |  |n  |  |    //
//    |  | 1 |  |    //
//     \ |  c| /     //
//      \|ooo|/      //
//       '---'       //
//                   //
//                   //
///////////////////////


contract N1CO is ERC721Creator {
    constructor() ERC721Creator("#1 crush open edition", "N1CO") {}
}