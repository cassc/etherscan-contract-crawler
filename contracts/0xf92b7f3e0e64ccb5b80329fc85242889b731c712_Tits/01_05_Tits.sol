// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tits
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    Hoffer    //
//              //
//              //
//////////////////


contract Tits is ERC721Creator {
    constructor() ERC721Creator("Tits", "Tits") {}
}