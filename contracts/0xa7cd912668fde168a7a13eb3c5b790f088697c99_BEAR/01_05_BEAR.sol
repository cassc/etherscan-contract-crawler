// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 1 / 1 From Bear
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    1-1 BEAR    //
//                //
//                //
////////////////////


contract BEAR is ERC721Creator {
    constructor() ERC721Creator("1 / 1 From Bear", "BEAR") {}
}