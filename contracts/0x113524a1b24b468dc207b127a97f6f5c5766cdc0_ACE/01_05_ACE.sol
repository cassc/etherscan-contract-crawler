// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A/C Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    A/C Editions    //
//                    //
//                    //
////////////////////////


contract ACE is ERC721Creator {
    constructor() ERC721Creator("A/C Editions", "ACE") {}
}