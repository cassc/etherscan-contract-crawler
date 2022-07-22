// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: water
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                                                                      //
//                                                                                      //
//    ┬ ┬┌─┐┌┬┐┌─┐┬─┐                                                                   //
//    │││├─┤ │ ├┤ ├┬┘                                                                   //
//    └┴┘┴ ┴ ┴ └─┘┴└─                                                                   //
//                                                                                      //
//                                                                                      //
//                                                                                      //
//                                                                                      //
//                                                                                      //
//                                                                                      //
//                                                                                      //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////


contract water is ERC721Creator {
    constructor() ERC721Creator("water", "water") {}
}