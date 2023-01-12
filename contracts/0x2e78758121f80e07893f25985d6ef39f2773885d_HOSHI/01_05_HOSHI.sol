// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HOSHI
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//      _    _  ____   _____ _    _ _____     //
//     | |  | |/ __ \ / ____| |  | |_   _|    //
//     | |__| | |  | | (___ | |__| | | |      //
//     |  __  | |  | |\___ \|  __  | | |      //
//     | |  | | |__| |____) | |  | |_| |_     //
//     |_|  |_|\____/|_____/|_|  |_|_____|    //
//                                            //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract HOSHI is ERC721Creator {
    constructor() ERC721Creator("HOSHI", "HOSHI") {}
}