// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: October's Unique Curiosities
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    ╔═╗┌─┐┌┬┐┌─┐┌┐ ┌─┐┬─┐┌─┐       //
//    ║ ║│   │ │ │├┴┐├┤ ├┬┘└─┐       //
//    ╚═╝└─┘ ┴ └─┘└─┘└─┘┴└─└─┘       //
//    ╦ ╦┌┐┌┬┌─┐ ┬ ┬┌─┐              //
//    ║ ║│││││─┼┐│ │├┤               //
//    ╚═╝┘└┘┴└─┘└└─┘└─┘              //
//    ╔═╗┬ ┬┬─┐┬┌─┐┌─┐┬┌┬┐┬┌─┐┌─┐    //
//    ║  │ │├┬┘││ │└─┐│ │ │├┤ └─┐    //
//    ╚═╝└─┘┴└─┴└─┘└─┘┴ ┴ ┴└─┘└─┘    //
//                                   //
//                                   //
///////////////////////////////////////


contract OUN is ERC721Creator {
    constructor() ERC721Creator("October's Unique Curiosities", "OUN") {}
}