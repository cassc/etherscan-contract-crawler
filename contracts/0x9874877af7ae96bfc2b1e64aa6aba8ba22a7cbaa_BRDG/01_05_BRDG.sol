// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bridge DSGN
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//        ____       _     _                  //
//       | __ ) _ __(_) __| | __ _  ___       //
//       |  _ \| '__| |/ _` |/ _` |/ _ \      //
//      _| |_) | |  | | (_| | (_| |  __/_     //
//     (_)____/|_|  |_|\__,_|\__, |\___(_)    //
//                           |___/            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract BRDG is ERC1155Creator {
    constructor() ERC1155Creator("Bridge DSGN", "BRDG") {}
}