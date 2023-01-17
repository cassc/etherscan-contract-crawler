// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fantasy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//     __  __       _                 _     //
//    |  \/  |     | |               | |    //
//    | \  / | ___ | | ___  _   _  __| |    //
//    | |\/| |/ _ \| |/ _ \| | | |/ _` |    //
//    | |  | | (_) | | (_) | |_| | (_| |    //
//    |_|  |_|\___/|_|\___/ \__,_|\__,_|    //
//                                          //
//                                          //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract Dream is ERC721Creator {
    constructor() ERC721Creator("Fantasy", "Dream") {}
}