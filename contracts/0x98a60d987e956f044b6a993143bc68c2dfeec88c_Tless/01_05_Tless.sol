// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Timeless by Kim Henry
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//                                         //
//    . . .-. .  . . . .-. . . .-. . .     //
//    |<   |  |\/| |-| |-  |\| |(   |      //
//    ' ` `-' '  ` ' ` `-' ' ` ' '  `      //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract Tless is ERC721Creator {
    constructor() ERC721Creator("Timeless by Kim Henry", "Tless") {}
}