// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EMOTIONS, THOUGHTS AND DREAMS.
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//                                    //
//      ______   _______   _____      //
//     |  ____| |__   __| |  __ \     //
//     | |__       | |    | |  | |    //
//     |  __|      | |    | |  | |    //
//     | |____     | |    | |__| |    //
//     |______|    |_|    |_____/     //
//                                    //
//                                    //
//                                    //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract ETD is ERC721Creator {
    constructor() ERC721Creator("EMOTIONS, THOUGHTS AND DREAMS.", "ETD") {}
}