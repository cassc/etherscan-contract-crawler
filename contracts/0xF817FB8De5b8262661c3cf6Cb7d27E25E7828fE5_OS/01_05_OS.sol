// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OHAYA
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    Welcome to Ohaya Studio!    //
//                                //
//                                //
////////////////////////////////////


contract OS is ERC721Creator {
    constructor() ERC721Creator("OHAYA", "OS") {}
}