// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Savvy's Art Collection
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//        =/\                 /\=        //
//        / \'._   (\_/)   _.'/ \        //
//       / .''._'--(o.o)--'_.''. \       //
//      /.' _/ |`'=/ " \='`| \_ `.\      //
//     /` .' `\;-,'\___/',-;/` '. '\     //
//    /.-'       `\(-V-)/`       `-.\    //
//    `            "   "            `    //
//                                       //
//                                       //
///////////////////////////////////////////


contract SAV is ERC721Creator {
    constructor() ERC721Creator("Savvy's Art Collection", "SAV") {}
}