// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LOVE 22
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//       __   ____ _   ______  ___  ___     //
//      / /  / __ \ | / / __/ |_  ||_  |    //
//     / /__/ /_/ / |/ / _/  / __// __/     //
//    /____/\____/|___/___/ /____/____/     //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract L22 is ERC721Creator {
    constructor() ERC721Creator("LOVE 22", "L22") {}
}