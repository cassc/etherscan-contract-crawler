// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ftest
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    ftest    //
//             //
//             //
/////////////////


contract ftest is ERC721Creator {
    constructor() ERC721Creator("ftest", "ftest") {}
}