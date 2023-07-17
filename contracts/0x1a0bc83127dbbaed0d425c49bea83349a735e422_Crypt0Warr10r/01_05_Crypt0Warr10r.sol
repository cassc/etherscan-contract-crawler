// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Crypt0Warr10r
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    Crypt0Warr10r Contract    //
//                              //
//                              //
//////////////////////////////////


contract Crypt0Warr10r is ERC721Creator {
    constructor() ERC721Creator("Crypt0Warr10r", "Crypt0Warr10r") {}
}