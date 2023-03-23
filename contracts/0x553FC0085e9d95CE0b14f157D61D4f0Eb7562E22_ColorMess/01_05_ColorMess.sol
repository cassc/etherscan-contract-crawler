// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ColorMess
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    ColorMess    //
//                 //
//                 //
/////////////////////


contract ColorMess is ERC1155Creator {
    constructor() ERC1155Creator("ColorMess", "ColorMess") {}
}