// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Firstopepen
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    I’m not an artist, so i made art     //
//                                         //
//                                         //
/////////////////////////////////////////////


contract Checks is ERC1155Creator {
    constructor() ERC1155Creator("Firstopepen", "Checks") {}
}