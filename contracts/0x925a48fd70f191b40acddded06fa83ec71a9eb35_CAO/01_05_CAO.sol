// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cao - Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                                               //
//     /¯¯¯/\__) °  )¯¯,¯\ °  /¯¯,¯¯\            //
//    |\     \/¯¯¯)  /__/'\__\ |\____ /|'        //
//     \|¯¯¯¯¯¯|  |__ |/\|__|' \|___ |/ °        //
//       ¯¯¯¯¯¯'  '                              //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract CAO is ERC1155Creator {
    constructor() ERC1155Creator("Cao - Editions", "CAO") {}
}