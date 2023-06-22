// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Putin
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    This is Putin    //
//                     //
//                     //
/////////////////////////


contract PUTIN is ERC721Creator {
    constructor() ERC721Creator("Putin", "PUTIN") {}
}