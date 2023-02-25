// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepe Milady Taker
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    " $ "    //
//             //
//             //
/////////////////


contract PMT is ERC721Creator {
    constructor() ERC721Creator("Pepe Milady Taker", "PMT") {}
}