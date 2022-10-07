// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Getaway
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    ~ THE GETAWAY BY ALISTER MORI ~    //
//                                       //
//                                       //
///////////////////////////////////////////


contract GETAWAY is ERC721Creator {
    constructor() ERC721Creator("The Getaway", "GETAWAY") {}
}