// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE LAST CONFIRMATION
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                   +--------+      //
//                 /        /|       //
//                /        / |       //
//               /        /  |       //
//              /        /   |       //
//             +--------+    |       //
//            /|        |    /|      //
//           / |        |   / |      //
//          /  |        |  /  |      //
//         /   |        | /   |      //
//        +--------+    |/    |      //
//        |    |    |    +------+    //
//        |    |    |   /|    |      //
//        +----|----+  / |    |      //
//             |        /  |    |    //
//             |       /   |    |    //
//             |      /    |    |    //
//             +-----+-----+----+    //
//                                   //
//                                   //
///////////////////////////////////////


contract TLC is ERC1155Creator {
    constructor() ERC1155Creator("THE LAST CONFIRMATION", "TLC") {}
}