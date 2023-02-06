// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Stories of Despair
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                                   .  .       //
//    .-.-. .-.  .-.-. .-.  .-. .-.  |  . .-    //
//    ' ' ' `-`- ' ' ' `-`- '   `-`- '- ' `-    //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract MMRLC is ERC721Creator {
    constructor() ERC721Creator("Stories of Despair", "MMRLC") {}
}