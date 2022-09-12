// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: daehandope
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    Artxx    //
//             //
//             //
/////////////////


contract DAE is ERC721Creator {
    constructor() ERC721Creator("daehandope", "DAE") {}
}