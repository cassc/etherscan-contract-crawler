// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: pile of poo
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//     ________  ________  ________       //
//    |\   __  \|\   __  \|\   __  \      //
//    \ \  \|\  \ \  \|\  \ \  \|\  \     //
//     \ \   ____\ \  \\\  \ \   ____\    //
//      \ \  \___|\ \  \\\  \ \  \___|    //
//       \ \__\    \ \_______\ \__\       //
//        \|__|     \|_______|\|__|       //
//                                        //
//                                        //
////////////////////////////////////////////


contract POP is ERC1155Creator {
    constructor() ERC1155Creator("pile of poo", "POP") {}
}