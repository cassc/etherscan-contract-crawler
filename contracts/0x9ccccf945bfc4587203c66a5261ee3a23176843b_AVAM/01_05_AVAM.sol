// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Avatar Master
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Avatar Master    //
//                     //
//                     //
/////////////////////////


contract AVAM is ERC721Creator {
    constructor() ERC721Creator("Avatar Master", "AVAM") {}
}