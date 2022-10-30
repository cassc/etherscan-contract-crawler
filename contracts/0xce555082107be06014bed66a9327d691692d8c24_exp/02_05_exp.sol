// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Experimental
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    ( ͡❛ ͜ʖ͡❛ )    //
//                   //
//                   //
///////////////////////


contract exp is ERC721Creator {
    constructor() ERC721Creator("Experimental", "exp") {}
}