// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Azuki #1526
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////
//          //
//          //
//    rf    //
//          //
//          //
//////////////


contract Azuki is ERC721Creator {
    constructor() ERC721Creator("Azuki #1526", "Azuki") {}
}