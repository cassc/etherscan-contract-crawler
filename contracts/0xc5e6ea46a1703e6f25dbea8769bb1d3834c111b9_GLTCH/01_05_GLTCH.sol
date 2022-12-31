// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GLITCH TOWN ARCADE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    ┌─┐┬  ┬┌┬┐┌─┐┬ ┬  ┌┬┐┌─┐┬ ┬┌┐┌  ┌─┐┬─┐┌─┐┌─┐┌┬┐┌─┐    //
//    │ ┬│  │ │ │  ├─┤   │ │ │││││││  ├─┤├┬┘│  ├─┤ ││├┤     //
//    └─┘┴─┘┴ ┴ └─┘┴ ┴   ┴ └─┘└┴┘┘└┘  ┴ ┴┴└─└─┘┴ ┴─┴┘└─┘    //
//                                                          //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract GLTCH is ERC721Creator {
    constructor() ERC721Creator("GLITCH TOWN ARCADE", "GLTCH") {}
}