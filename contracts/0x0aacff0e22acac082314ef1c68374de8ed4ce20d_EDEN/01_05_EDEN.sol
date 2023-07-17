// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Roadmap to E-DEN
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    ╦═╗┌─┐┌─┐┌┬┐┌┬┐┌─┐┌─┐    //
//    ╠╦╝│ │├─┤ │││││├─┤├─┘    //
//    ╩╚═└─┘┴ ┴─┴┘┴ ┴┴ ┴┴      //
//    ┌┬┐┌─┐  ╔═╗ ╔╦╗╔═╗╔╗╔    //
//     │ │ │  ║╣───║║║╣ ║║║    //
//     ┴ └─┘  ╚═╝ ═╩╝╚═╝╝╚╝    //
//                             //
//                             //
/////////////////////////////////


contract EDEN is ERC721Creator {
    constructor() ERC721Creator("Roadmap to E-DEN", "EDEN") {}
}