// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: themeanscreator
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    ████████╗███╗   ███╗ ██████╗    //
//    ╚══██╔══╝████╗ ████║██╔════╝    //
//       ██║   ██╔████╔██║██║         //
//       ██║   ██║╚██╔╝██║██║         //
//       ██║   ██║ ╚═╝ ██║╚██████╗    //
//       ╚═╝   ╚═╝     ╚═╝ ╚═════╝    //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract TMC is ERC1155Creator {
    constructor() ERC1155Creator("themeanscreator", "TMC") {}
}