// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Metropolis
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//                                    //
//    ╔╦╗┌─┐┌┬┐┬─┐┌─┐┌─┐┌─┐┬  ┬┌─┐    //
//    ║║║├┤  │ ├┬┘│ │├─┘│ ││  │└─┐    //
//    ╩ ╩└─┘ ┴ ┴└─└─┘┴  └─┘┴─┘┴└─┘    //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract CITY is ERC721Creator {
    constructor() ERC721Creator("Metropolis", "CITY") {}
}