// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: YOO
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    OO    //
//          //
//          //
//////////////


contract YoY is ERC721Creator {
    constructor() ERC721Creator("YOO", "YoY") {}
}