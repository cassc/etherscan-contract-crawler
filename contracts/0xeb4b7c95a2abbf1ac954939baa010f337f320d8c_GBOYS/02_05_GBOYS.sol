// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Green Boys
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Green Boys Family    //
//                         //
//                         //
/////////////////////////////


contract GBOYS is ERC721Creator {
    constructor() ERC721Creator("Green Boys", "GBOYS") {}
}