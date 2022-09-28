// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: doodle
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////
//         //
//         //
//    c    //
//         //
//         //
/////////////


contract doodle is ERC721Creator {
    constructor() ERC721Creator("doodle", "doodle") {}
}