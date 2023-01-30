// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ANON
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//     .----.-----.-----.-----.           //
//     /      \     \     \     \         //
//    |  \/    |     |   __L_____L__      //
//    |   |    |     |  (           \     //
//    |    \___/    /    \______/    |    //
//    |        \___/\___/\___/       |    //
//     \      \     /               /     //
//      |                        __/      //
//       \_                   __/         //
//        |        |         |            //
//        |                  |            //
//        |                  |            //
//                                        //
//                                        //
////////////////////////////////////////////


contract ANON is ERC1155Creator {
    constructor() ERC1155Creator("ANON", "ANON") {}
}