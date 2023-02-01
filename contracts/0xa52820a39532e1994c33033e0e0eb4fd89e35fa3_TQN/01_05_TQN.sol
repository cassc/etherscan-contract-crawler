// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE QUEEN
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//      _______ ____  _   _     //
//     |__   __/ __ \| \ | |    //
//        | | | |  | |  \| |    //
//        | | | |  | | . ` |    //
//        | | | |__| | |\  |    //
//        |_|  \___\_\_| \_|    //
//                              //
//                              //
//                              //
//                              //
//////////////////////////////////


contract TQN is ERC721Creator {
    constructor() ERC721Creator("THE QUEEN", "TQN") {}
}