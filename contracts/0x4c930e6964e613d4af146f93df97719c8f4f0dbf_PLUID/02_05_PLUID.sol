// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PLUIDNFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//    PLUID!    //
//              //
//              //
//////////////////


contract PLUID is ERC721Creator {
    constructor() ERC721Creator("PLUIDNFT", "PLUID") {}
}