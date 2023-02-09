// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Capitulation Checks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    Capitulation    //
//                    //
//                    //
////////////////////////


contract Capit is ERC721Creator {
    constructor() ERC721Creator("Capitulation Checks", "Capit") {}
}