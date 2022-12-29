// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Martovsky
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//    8b   d8 888b. 88888 Yb    dP .d88b. 8  dP          //
//    8YbmdP8 8  .8   8    Yb  dP  YPwww. 8wdP           //
//    8  "  8 8wwK'   8     YbdP       d8 88Yb           //
//    8     8 8  Yb   8      YP    `Y88P' 8  Yb          //
//                                                       //
//                                                       //
//    Thanks for being interested in my art!             //
//    If you would like to purchase a physical copy,     //
//    or inquire about commercial use,                   //
//    please contact me.                                 //
//                                                       //
//    mail / [email protected]                           //
//    insta / @martovsky_                                //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract MRTVSK is ERC1155Creator {
    constructor() ERC1155Creator("Martovsky", "MRTVSK") {}
}