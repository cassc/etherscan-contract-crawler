// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: An Autumn in Alsace
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//                                                              //
//       __|    \     \ |   _ \   |  | __| _ _|  _ \    \       //
//     \__ \   _ \   .  |  (   |  |  | _|    |     /   _ \      //
//     ____/ _/  _\ _|\_| \__\_\ \__/ ___| ___| _|_\ _/  _\     //
//                                                              //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract ALSAC is ERC721Creator {
    constructor() ERC721Creator("An Autumn in Alsace", "ALSAC") {}
}