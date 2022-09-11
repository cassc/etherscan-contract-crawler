// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WL721
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    teest    //
//             //
//             //
/////////////////


contract wl is ERC721Creator {
    constructor() ERC721Creator("WL721", "wl") {}
}