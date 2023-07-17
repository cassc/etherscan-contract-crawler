// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lust and tears
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//                            //
//      _     _   _ _____     //
//     | |   | \ | |_   _|    //
//     | |   |  \| | | |      //
//     | |___| |\  | | |      //
//     |_____|_| \_| |_|      //
//                            //
//                            //
//                            //
//                            //
////////////////////////////////


contract LNT is ERC721Creator {
    constructor() ERC721Creator("Lust and tears", "LNT") {}
}