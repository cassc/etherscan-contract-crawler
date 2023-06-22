// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Purpose Of Light.
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    Misan Harriman    //
//                      //
//                      //
//////////////////////////


contract POL is ERC721Creator {
    constructor() ERC721Creator("The Purpose Of Light.", "POL") {}
}