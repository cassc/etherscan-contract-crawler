// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: godgirl
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    zhang    //
//             //
//             //
/////////////////


contract gg is ERC721Creator {
    constructor() ERC721Creator("godgirl", "gg") {}
}