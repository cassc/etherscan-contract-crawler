// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fantasy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    :3    //
//          //
//          //
//////////////


contract FA is ERC721Creator {
    constructor() ERC721Creator("Fantasy", "FA") {}
}