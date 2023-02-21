// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: naïf
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//                            //
//                  _  __     //
//                 (_)/ _|    //
//      _ __   __ _ _| |_     //
//     | '_ \ / _` | |  _|    //
//     | | | | (_| | | |      //
//     |_| |_|\__,_|_|_|      //
//                            //
//                            //
//                            //
//                            //
////////////////////////////////


contract NAIF is ERC721Creator {
    constructor() ERC721Creator(unicode"naïf", "NAIF") {}
}