// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shift.jpg
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    :)    //
//          //
//          //
//////////////


contract Shft is ERC721Creator {
    constructor() ERC721Creator("Shift.jpg", "Shft") {}
}