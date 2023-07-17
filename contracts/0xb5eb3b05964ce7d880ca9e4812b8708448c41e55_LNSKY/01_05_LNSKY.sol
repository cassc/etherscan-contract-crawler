// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lansky
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//             ________             //
//             |""""""|             //
//             |LANSKY|             //
//            //      \\            //
//           //        \\           //
//          //          \\          //
//         //            \\         //
//        //              \\        //
//       //                \\       //
//      //                  \\      //
//     //                    \\     //
//    //   /  /   |   \  \    \\    //
//                                  //
//      ___                         //
//     /o o\                        //
//    |  o  |                       //
//     \___/                        //
//                                  //
//                                  //
//////////////////////////////////////


contract LNSKY is ERC721Creator {
    constructor() ERC721Creator("Lansky", "LNSKY") {}
}