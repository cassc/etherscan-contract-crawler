// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: counter.culture
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    ┌─┐┌─┐┬ ┬┌┐┌┌┬┐┌─┐┬─┐ ┌─┐┬ ┬┬ ┌┬┐┬ ┬┬─┐┌─┐    //
//    │  │ ││ ││││ │ ├┤ ├┬┘ │  │ ││  │ │ │├┬┘├┤     //
//    └─┘└─┘└─┘┘└┘ ┴ └─┘┴└─o└─┘└─┘┴─┘┴ └─┘┴└─└─┘    //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract CC is ERC721Creator {
    constructor() ERC721Creator("counter.culture", "CC") {}
}