// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Once Upon in Persia
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
    constructor() ERC721Creator("Once Upon in Persia", "MMRLC") {}
}