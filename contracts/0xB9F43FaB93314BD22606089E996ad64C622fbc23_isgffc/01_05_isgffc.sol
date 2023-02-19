// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: i support global fund for children
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    https://thegivingblock.com/donate/global-fund-for-children/                         //
//                                                                                        //
//    the contract is created by me                                                       //
//    christian albert mueller                                                            //
//    https://spaceisjoy.com                                                              //
//                                                                                        //
//    i am not associated with global fund for children                                   //
//    and this is a personal art and charity project of mine.                             //
//                                                                                        //
//    eth receiver is: 0x717B42d148a429b3408Db2AB0Eb35e245671bb5E                         //
//    and came provided by https://thegivingblock.com/donate/global-fund-for-children/    //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//              _____                                                                     //
//             /\    \                                                                    //
//            /::\____\                                                                   //
//           /:::/    /                                                                   //
//          /:::/    /                                                                    //
//         /:::/    /                                                                     //
//        /:::/____/                                                                      //
//       /::::\    \                                                                      //
//      /::::::\____\________                                                             //
//     /:::/\:::::::::::\    \                                                            //
//    /:::/  |:::::::::::\____\                                                           //
//    \::/   |::|~~~|~~~~~                                                                //
//     \/____|::|   |                                                                     //
//           |::|   |                                                                     //
//           |::|   |                                                                     //
//           |::|   |                                                                     //
//           |::|   |                                                                     //
//           |::|   |                                                                     //
//           \::|   |                                                                     //
//            \:|   |                                                                     //
//             \|___|                                                                     //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract isgffc is ERC1155Creator {
    constructor() ERC1155Creator("i support global fund for children", "isgffc") {}
}