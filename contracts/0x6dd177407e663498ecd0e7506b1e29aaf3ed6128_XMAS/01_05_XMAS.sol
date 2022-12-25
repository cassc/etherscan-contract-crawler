// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Naughty or NicΞ
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//               ____                   //
//              /    \                  //
//     ._.     /___/\ \                 //
//    :(_):    |6.9| \|                 //
//      \\     '.-.'  O                 //
//       \\____.-"-.____                //
//       '----|     |--.\               //
//            |==[]=|  _\\_             //
//             \___/    /|\             //
//             // \\                    //
//            //   \\                   //
//            \\    \\  Merry Xmas      //
//            _\\    \\__    Paul xo    //
//           (___|    \__)              //
//                                      //
//                                      //
//////////////////////////////////////////


contract XMAS is ERC1155Creator {
    constructor() ERC1155Creator(unicode"Naughty or NicΞ", "XMAS") {}
}