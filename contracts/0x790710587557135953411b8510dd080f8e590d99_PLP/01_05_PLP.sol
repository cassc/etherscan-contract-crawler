// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PEPE LA PULGA
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//     ________  ___       ________       //
//    |\   __  \|\  \     |\   __  \      //
//    \ \  \|\  \ \  \    \ \  \|\  \     //
//     \ \   ____\ \  \    \ \   ____\    //
//      \ \  \___|\ \  \____\ \  \___|    //
//       \ \__\    \ \_______\ \__\       //
//        \|__|     \|_______|\|__|       //
//                                        //
//                                        //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract PLP is ERC1155Creator {
    constructor() ERC1155Creator("PEPE LA PULGA", "PLP") {}
}