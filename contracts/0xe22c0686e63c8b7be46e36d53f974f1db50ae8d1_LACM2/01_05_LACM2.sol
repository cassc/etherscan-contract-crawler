// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Life Story of the City of Los Angeles v2
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    SAGEN LIFE 2    //
//                    //
//                    //
////////////////////////


contract LACM2 is ERC721Creator {
    constructor() ERC721Creator("The Life Story of the City of Los Angeles v2", "LACM2") {}
}