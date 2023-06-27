// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: S7N
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                                              //
//                                              //
//    .oooooo..o  ooooooooo ooooo      ooo      //
//    d8P'    `Y8 d"""""""8' `888b.     `8'     //
//    Y88bo.            .8'   8 `88b.    8      //
//     `"Y8888o.       .8'    8   `88b.  8      //
//         `"Y88b     .8'     8     `88b.8      //
//    oo     .d8P    .8'      8       `888      //
//    8""88888P'    .8'      o8o        `8      //
//                                              //
//                                              //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract S7N is ERC721Creator {
    constructor() ERC721Creator("S7N", "S7N") {}
}