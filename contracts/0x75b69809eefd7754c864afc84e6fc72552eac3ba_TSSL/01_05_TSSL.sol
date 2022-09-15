// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Sandbox Sale Land
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    The Sandbox Sale Land    //
//                             //
//                             //
/////////////////////////////////


contract TSSL is ERC721Creator {
    constructor() ERC721Creator("The Sandbox Sale Land", "TSSL") {}
}