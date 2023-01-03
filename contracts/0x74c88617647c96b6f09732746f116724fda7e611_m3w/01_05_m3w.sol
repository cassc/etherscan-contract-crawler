// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tha Journey
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    ____   _____  __ __  _____      //
//    /  _/  /  _  \/  |  \/   __\    //
//    |  |---|  |  |\  |  /|   __|    //
//    \_____/\_____/ \___/ \_____/    //
//                                    //
//                                    //
////////////////////////////////////////


contract m3w is ERC721Creator {
    constructor() ERC721Creator("Tha Journey", "m3w") {}
}