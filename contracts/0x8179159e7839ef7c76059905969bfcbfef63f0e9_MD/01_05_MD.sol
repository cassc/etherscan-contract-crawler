// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mad DJ
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    noooo    //
//             //
//             //
/////////////////


contract MD is ERC721Creator {
    constructor() ERC721Creator("Mad DJ", "MD") {}
}