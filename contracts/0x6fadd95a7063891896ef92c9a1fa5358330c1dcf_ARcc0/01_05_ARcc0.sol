// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Aslan Ruby cc0
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//                                                //
//    ╔═╗╔═╗╦  ╔═╗╔╗╔  ╔═╗╔═╗┌─┐  ╦═╗╦ ╦╔╗ ╦ ╦    //
//    ╠═╣╚═╗║  ╠═╣║║║  ║  ║  │ │  ╠╦╝║ ║╠╩╗╚╦╝    //
//    ╩ ╩╚═╝╩═╝╩ ╩╝╚╝  ╚═╝╚═╝└─┘  ╩╚═╚═╝╚═╝ ╩     //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract ARcc0 is ERC721Creator {
    constructor() ERC721Creator("Aslan Ruby cc0", "ARcc0") {}
}