// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: xusha
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                           _                 //
//                          | |                //
//     __  __  _   _   ___  | |__     __ _     //
//     \ \/ / | | | | / __| | '_ \   / _` |    //
//      >  <  | |_| | \__ \ | | | | | (_| |    //
//     /_/\_\  \__,_| |___/ |_| |_|  \__,_|    //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract xu is ERC721Creator {
    constructor() ERC721Creator("xusha", "xu") {}
}