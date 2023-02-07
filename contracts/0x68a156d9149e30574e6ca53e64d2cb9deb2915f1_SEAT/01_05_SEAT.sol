// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SEAT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//                                    //
//     __    __  ____  ____  _  _     //
//    (  )  (  )(  _ \(  _ \( \/ )    //
//    / (_/\ )(  ) _ ( ) _ ( )  /     //
//    \____/(__)(____/(____/(__/      //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract SEAT is ERC721Creator {
    constructor() ERC721Creator("SEAT", "SEAT") {}
}