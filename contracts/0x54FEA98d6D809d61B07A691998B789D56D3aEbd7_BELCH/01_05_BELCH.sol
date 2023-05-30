// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: belch
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    shit    //
//            //
//            //
////////////////


contract BELCH is ERC721Creator {
    constructor() ERC721Creator("belch", "BELCH") {}
}