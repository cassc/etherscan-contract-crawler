// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MEME by NO ART
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//      __  __ ______ __  __ ______   _             _   _  ____             _____ _______     //
//     |  \/  |  ____|  \/  |  ____| | |           | \ | |/ __ \      /\   |  __ \__   __|    //
//     | \  / | |__  | \  / | |__    | |__  _   _  |  \| | |  | |    /  \  | |__) | | |       //
//     | |\/| |  __| | |\/| |  __|   | '_ \| | | | | . ` | |  | |   / /\ \ |  _  /  | |       //
//     | |  | | |____| |  | | |____  | |_) | |_| | | |\  | |__| |  / ____ \| | \ \  | |       //
//     |_|  |_|______|_|  |_|______| |_.__/ \__, | |_| \_|\____/  /_/    \_\_|  \_\ |_|       //
//                                           __/ |                                            //
//                                          |___/                                             //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract MNA is ERC721Creator {
    constructor() ERC721Creator("MEME by NO ART", "MNA") {}
}