// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: YourSoul
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Your Soul HERE...    //
//                         //
//                         //
/////////////////////////////


contract YS is ERC1155Creator {
    constructor() ERC1155Creator("YourSoul", "YS") {}
}