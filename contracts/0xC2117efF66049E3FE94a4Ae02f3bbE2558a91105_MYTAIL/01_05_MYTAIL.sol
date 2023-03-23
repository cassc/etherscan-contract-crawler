// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MYTAIL
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    　 　 *　　　　*                             //
//    　 　 　 　 　 　*                           //
//    　　　 　 　 　 　 *                          //
//    　 　 　 　 　 　　 *                         //
//    　　　　　　　　　　　*                           //
//    　　　　　　　　　　　 *                          //
//    　 　 　 　 　　　　　　　　　　　　　　　　　　　　　*         //
//    　　　　　　　　　　　　　　　　　　　　　　　　　　 *           //
//    　　　　　　　　　　　　　　　　　　　　　　　　　　*            //
//    　　　　　　　　　　　　　　　　　　　　　　　　　*             //
//    　　　　　　　　　　　　　　　　　　　　　　　　　*             //
//    　　　　　　　　　　　　　　　　　　　　　　　　　　*            //
//    　 　 　 　 　 　 　 　 　 　 　 　 　 　 　 　 　 *    //
//                                           //
//                                           //
///////////////////////////////////////////////


contract MYTAIL is ERC1155Creator {
    constructor() ERC1155Creator("MYTAIL", "MYTAIL") {}
}