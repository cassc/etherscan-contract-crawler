// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lili Hazini
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//      _      _ _ _   _    _           _       _     //
//     | |    (_) (_) | |  | |         (_)     (_)    //
//     | |     _| |_  | |__| | __ _ _____ _ __  _     //
//     | |    | | | | |  __  |/ _` |_  / | '_ \| |    //
//     | |____| | | | | |  | | (_| |/ /| | | | | |    //
//     |______|_|_|_| |_|  |_|\__,_/___|_|_| |_|_|    //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract LH1 is ERC721Creator {
    constructor() ERC721Creator("Lili Hazini", "LH1") {}
}