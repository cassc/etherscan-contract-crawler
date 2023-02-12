// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Carezza
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////
//                                //
//                                //
//                                //
//    ╔═══╗                       //
//    ║╔═╗║                       //
//    ║║─╚╬══╦═╦══╦═══╦═══╦══╗    //
//    ║║─╔╣╔╗║╔╣║═╬══║╠══║║╔╗║    //
//    ║╚═╝║╔╗║║║║═╣║══╣║══╣╔╗║    //
//    ╚═══╩╝╚╩╝╚══╩═══╩═══╩╝╚╝    //
//                                //
//    by reymark.eth              //
//                                //
//                                //
//                                //
//                                //
//                                //
//                                //
//                                //
//                                //
////////////////////////////////////


contract CRZ is ERC1155Creator {
    constructor() ERC1155Creator("Carezza", "CRZ") {}
}