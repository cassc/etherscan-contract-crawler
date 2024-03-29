// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Segwitnitwit Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//                                         __          //
//                                      __/\ \__       //
//      ____     __     __   __  __  __/\_\ \ ,_\      //
//     /',__\  /'__`\ /'_ `\/\ \/\ \/\ \/\ \ \ \/      //
//    /\__, `\/\  __//\ \L\ \ \ \_/ \_/ \ \ \ \ \_     //
//    \/\____/\ \____\ \____ \ \___x___/'\ \_\ \__\    //
//     \/___/  \/____/\/___L\ \/__//__/   \/_/\/__/    //
//                      /\____/                        //
//                      \_/__/                         //
//              __                    __               //
//           __/\ \__              __/\ \__            //
//      ___ /\_\ \ ,_\  __  __  __/\_\ \ ,_\           //
//    /' _ `\/\ \ \ \/ /\ \/\ \/\ \/\ \ \ \/           //
//    /\ \/\ \ \ \ \ \_\ \ \_/ \_/ \ \ \ \ \_          //
//    \ \_\ \_\ \_\ \__\\ \___x___/'\ \_\ \__\         //
//     \/_/\/_/\/_/\/__/ \/__//__/   \/_/\/__/         //
//                                                     //
//                                                     //
//             __                                      //
//            /\ \                                     //
//       __   \_\ \    ____                            //
//     /'__`\ /'_` \  /',__\                           //
//    /\  __//\ \L\ \/\__, `\__                        //
//    \ \____\ \___,_\/\____/\_\                       //
//     \/____/\/__,_ /\/___/\/_/                       //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract seg is ERC1155Creator {
    constructor() ERC1155Creator("Segwitnitwit Editions", "seg") {}
}