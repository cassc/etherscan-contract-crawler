// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BAGAPES
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    xoxox    //
//             //
//             //
/////////////////


contract BGPE is ERC721Creator {
    constructor() ERC721Creator("BAGAPES", "BGPE") {}
}