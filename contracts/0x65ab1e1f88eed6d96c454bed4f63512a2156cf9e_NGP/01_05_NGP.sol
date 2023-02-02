// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: nakamu Genesis Pass
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                                   //
//    ███╗ ██╗ ██████╗ ██████╗       //
//    ████╗ ██║██╔════╝ ██╔══██╗     //
//    ██╔██╗ ██║██║ ███╗██████╔╝     //
//    ██║╚██╗██║██║ ██║██╔═══╝       //
//    ██║ ╚████║╚██████╔╝██║         //
//    ╚═╝ ╚═══╝ ╚═════╝ ╚═╝          //
//                                   //
//                                   //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract NGP is ERC1155Creator {
    constructor() ERC1155Creator("nakamu Genesis Pass", "NGP") {}
}