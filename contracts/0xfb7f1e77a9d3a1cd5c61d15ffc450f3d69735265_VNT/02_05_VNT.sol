// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Garvanti
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//    \*\                /*/           /*/   */*/*/*/*/*/*    //
//     \*\              /*/\*\        /*/        /*/          //
//      \*\            /*/  \*\      /*/        /*/           //
//       \*\          /*/    \*\    /*/        /*/            //
//        \*\  /*/   /*/      \*\  /*/        /*/             //
//         \*\/*/   /*/        \*\/*/        /*/              //
//          \*\    /*/          \*\         /*/               //
//                                                            //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract VNT is ERC721Creator {
    constructor() ERC721Creator("Garvanti", "VNT") {}
}