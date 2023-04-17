// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Monkey by the lake
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//        ,#####,         //
//             #_   _#    //
//             |a` `a|    //
//             |  u  |    //
//    \\/ \//  (__d__)    //
//    / ,><. \ (e 8 e)    //
//    `""""""`  `Y"Y`     //
//                        //
//                        //
////////////////////////////


contract M8key is ERC1155Creator {
    constructor() ERC1155Creator("Monkey by the lake", "M8key") {}
}