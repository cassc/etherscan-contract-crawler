// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Toadz
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                   //
//                                                                                                   //
//                                                                                                   //
//                                                                      dddddddd                     //
//    TTTTTTTTTTTTTTTTTTTTTTT                                           d::::::d                     //
//    T:::::::::::::::::::::T                                           d::::::d                     //
//    T:::::::::::::::::::::T                                           d::::::d                     //
//    T:::::TT:::::::TT:::::T                                           d:::::d                      //
//    TTTTTT  T:::::T  TTTTTTooooooooooo     aaaaaaaaaaaaa      ddddddddd:::::d zzzzzzzzzzzzzzzzz    //
//            T:::::T      oo:::::::::::oo   a::::::::::::a   dd::::::::::::::d z:::::::::::::::z    //
//            T:::::T     o:::::::::::::::o  aaaaaaaaa:::::a d::::::::::::::::d z::::::::::::::z     //
//            T:::::T     o:::::ooooo:::::o           a::::ad:::::::ddddd:::::d zzzzzzzz::::::z      //
//            T:::::T     o::::o     o::::o    aaaaaaa:::::ad::::::d    d:::::d       z::::::z       //
//            T:::::T     o::::o     o::::o  aa::::::::::::ad:::::d     d:::::d      z::::::z        //
//            T:::::T     o::::o     o::::o a::::aaaa::::::ad:::::d     d:::::d     z::::::z         //
//            T:::::T     o::::o     o::::oa::::a    a:::::ad:::::d     d:::::d    z::::::z          //
//          TT:::::::TT   o:::::ooooo:::::oa::::a    a:::::ad::::::ddddd::::::dd  z::::::zzzzzzzz    //
//          T:::::::::T   o:::::::::::::::oa:::::aaaa::::::a d:::::::::::::::::d z::::::::::::::z    //
//          T:::::::::T    oo:::::::::::oo  a::::::::::aa:::a d:::::::::ddd::::dz:::::::::::::::z    //
//          TTTTTTTTTTT      ooooooooooo     aaaaaaaaaa  aaaa  ddddddddd   dddddzzzzzzzzzzzzzzzzz    //
//                                                                                                   //
//                                                                                                   //
//                                                                                                   //
//    Toadz - By Messhup                                                                             //
//                                                                                                   //
//                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////


contract Toadz is ERC1155Creator {
    constructor() ERC1155Creator("Toadz", "Toadz") {}
}