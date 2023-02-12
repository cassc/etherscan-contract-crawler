// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: objects|expressions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//                  //
//        |         //
//        |         //
//    ,-. | ,-.     //
//    | | | |-'     //
//    `-' | `-'     //
//                  //
//                  //
//                  //
//////////////////////


contract ole is ERC721Creator {
    constructor() ERC721Creator("objects|expressions", "ole") {}
}