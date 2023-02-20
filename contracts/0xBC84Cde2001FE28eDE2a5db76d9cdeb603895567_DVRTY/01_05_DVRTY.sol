// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Durtyphotos
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    DVRTY    //
//             //
//             //
/////////////////


contract DVRTY is ERC721Creator {
    constructor() ERC721Creator("Durtyphotos", "DVRTY") {}
}