// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sarah Woods Art Abstracts
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//    .d88b. Yb        dP    db       db        //
//    YPwww.  Yb  db  dP    dPYb     dPYb       //
//        d8   YbdPYbdP    dPwwYb   dPwwYb      //
//    `Y88P'    YP  YP    dP    Yb dP    Yb     //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract SWAA23 is ERC721Creator {
    constructor() ERC721Creator("Sarah Woods Art Abstracts", "SWAA23") {}
}