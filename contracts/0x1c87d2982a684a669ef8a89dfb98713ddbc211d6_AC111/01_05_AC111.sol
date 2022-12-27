// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AC111
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    AC111    //
//             //
//             //
/////////////////


contract AC111 is ERC721Creator {
    constructor() ERC721Creator("AC111", "AC111") {}
}