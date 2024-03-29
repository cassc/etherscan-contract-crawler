// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JERKS LORE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    ////////////////////////////////////////    //
//    //                                    //    //
//    //                                    //    //
//    //     ╦╔═╗╦═╗╦╔═╔═╗  ╦  ╔═╗╦═╗╔═╗    //    //
//    //     ║║╣ ╠╦╝╠╩╗╚═╗  ║  ║ ║╠╦╝║╣     //    //
//    //    ╚╝╚═╝╩╚═╩ ╩╚═╝  ╩═╝╚═╝╩╚═╚═╝    //    //
//    //                                    //    //
//    //                                    //    //
//    ////////////////////////////////////////    //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract JERKSLORE is ERC1155Creator {
    constructor() ERC1155Creator("JERKS LORE", "JERKSLORE") {}
}