// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MAGIC PEN
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    .  . .-. .-. .-.     //
//    |\/| |-| |..  |      //
//    '  ` ` ' `-' `-'     //
//                         //
//                         //
//                         //
/////////////////////////////


contract MAGIC is ERC721Creator {
    constructor() ERC721Creator("MAGIC PEN", "MAGIC") {}
}