// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: phenomenon
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////
//         //
//         //
//    ◍    //
//         //
//         //
/////////////


contract hello is ERC721Creator {
    constructor() ERC721Creator("phenomenon", "hello") {}
}