// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GM Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//     ██████╗ ██╗  ██╗██████╗ ██╗   ██╗       //
//    ██╔═████╗╚██╗██╔╝██╔══██╗╚██╗ ██╔╝       //
//    ██║██╔██║ ╚███╔╝ ██████╔╝ ╚████╔╝        //
//    ████╔╝██║ ██╔██╗ ██╔══██╗  ╚██╔╝         //
//    ╚██████╔╝██╔╝ ██╗██║  ██║   ██║          //
//     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝          //
//                                             //
//     0xry.com // Experiments in NFTs         //
//    0x: Project GM Editions by Ryan Edick    //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract GMEdition is ERC1155Creator {
    constructor() ERC1155Creator("GM Editions", "GMEdition") {}
}