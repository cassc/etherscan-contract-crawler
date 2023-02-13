// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NUO NAME
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//                              //
//      _   _ _    _  ____      //
//     | \ | | |  | |/ __ \     //
//     |  \| | |  | | |  | |    //
//     | . ` | |  | | |  | |    //
//     | |\  | |__| | |__| |    //
//     |_| \_|\____/ \____/     //
//                              //
//                              //
//                              //
//                              //
//                              //
//////////////////////////////////


contract NUO is ERC721Creator {
    constructor() ERC721Creator("NUO NAME", "NUO") {}
}