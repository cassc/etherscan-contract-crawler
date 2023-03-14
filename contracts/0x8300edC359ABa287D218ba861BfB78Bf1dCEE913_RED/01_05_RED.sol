// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Racheal’s editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//      _   _  _      //
//     |_) |_ | \     //
//     | \ |_ |_/     //
//                    //
//                    //
//                    //
////////////////////////


contract RED is ERC721Creator {
    constructor() ERC721Creator(unicode"Racheal’s editions", "RED") {}
}