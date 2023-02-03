// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CONWAY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//                                             //
//                                             //
//     _____ _____ _____ _ _ _ _____ __ __     //
//    |     |     |   | | | | |  _  |  |  |    //
//    |   --|  |  | | | | | | |     |_   _|    //
//    |_____|_____|_|___|_____|__|__| |_|      //
//                                             //
//                                             //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract CONWAY is ERC721Creator {
    constructor() ERC721Creator("CONWAY", "CONWAY") {}
}