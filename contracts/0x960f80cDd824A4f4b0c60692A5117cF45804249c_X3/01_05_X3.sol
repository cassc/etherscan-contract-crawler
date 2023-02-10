// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 3x3x3
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//      /\_\_\_\      //
//     /\/\_\_\_\     //
//    /\/\/\_\_\_\    //
//    \/\/\/_/_/_/    //
//     \/\/_/_/_/     //
//      \/_/_/_/      //
//                    //
//                    //
////////////////////////


contract X3 is ERC1155Creator {
    constructor() ERC1155Creator("3x3x3", "X3") {}
}