// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AliceInWonderland
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    Follow Mr. White Rabbit    //
//                               //
//                               //
///////////////////////////////////


contract AIW is ERC721Creator {
    constructor() ERC721Creator("AliceInWonderland", "AIW") {}
}