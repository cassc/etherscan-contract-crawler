// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Forever Okay
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    :)    //
//          //
//          //
//////////////


contract IM is ERC721Creator {
    constructor() ERC721Creator("Forever Okay", "IM") {}
}