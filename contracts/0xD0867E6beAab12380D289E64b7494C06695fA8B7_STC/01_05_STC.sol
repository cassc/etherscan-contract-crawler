// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Smol Test Contract
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////
//                          //
//                          //
//          /\              //
//         / *\             //
//        / *  \            //
//      ----------          //
//       | 0   0|           //
//       |______| - Smol    //
//                          //
//                          //
//////////////////////////////


contract STC is ERC1155Creator {
    constructor() ERC1155Creator("Smol Test Contract", "STC") {}
}