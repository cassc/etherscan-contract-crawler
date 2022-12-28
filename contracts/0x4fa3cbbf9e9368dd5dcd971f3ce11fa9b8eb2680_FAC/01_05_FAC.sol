// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Form and Content
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    Form and Content    //
//                        //
//                        //
////////////////////////////


contract FAC is ERC721Creator {
    constructor() ERC721Creator("Form and Content", "FAC") {}
}