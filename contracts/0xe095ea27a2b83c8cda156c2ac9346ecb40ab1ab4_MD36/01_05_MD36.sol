// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: moondust_36
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    ╔╦╗┌─┐┌─┐┌┐┌╔╦╗┬ ┬┌─┐┌┬┐    //
//    ║║║│ ││ ││││ ║║│ │└─┐ │     //
//    ╩ ╩└─┘└─┘┘└┘═╩╝└─┘└─┘ ┴     //
//                                //
//                                //
////////////////////////////////////


contract MD36 is ERC721Creator {
    constructor() ERC721Creator("moondust_36", "MD36") {}
}