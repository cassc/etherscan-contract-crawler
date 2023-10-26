// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chaos
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    ┌┐ ┬ ┬┬─┐┌─┐┌─┐┬┌─                //
//    ├┴┐│ │├┬┘│  ├─┤├┴┐                //
//    └─┘└─┘┴└─└─┘┴ ┴┴ ┴                //
//    ┌┐ ┌─┐┬─┐┌┐ ┌─┐┬─┐┌─┐┌─┐┬  ┬ ┬    //
//    ├┴┐├┤ ├┬┘├┴┐├┤ ├┬┘│ ││ ┬│  │ │    //
//    └─┘└─┘┴└─└─┘└─┘┴└─└─┘└─┘┴─┘└─┘    //
//                                      //
//                                      //
//////////////////////////////////////////


contract CHS is ERC721Creator {
    constructor() ERC721Creator("Chaos", "CHS") {}
}