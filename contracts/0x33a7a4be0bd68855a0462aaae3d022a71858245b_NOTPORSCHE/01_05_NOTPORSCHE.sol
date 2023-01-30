// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: This Is Not A Porsche
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    xoxox    //
//             //
//             //
/////////////////


contract NOTPORSCHE is ERC721Creator {
    constructor() ERC721Creator("This Is Not A Porsche", "NOTPORSCHE") {}
}