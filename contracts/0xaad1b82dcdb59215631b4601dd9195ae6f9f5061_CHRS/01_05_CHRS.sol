// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TO 2022 by GY
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//      ooooooo     ooooooo     ooooooo     ooooooo       //
//    o88     888 o888  o888o o88     888 o88     888     //
//          o888  888  8  888       o888        o888      //
//       o888   o 888o8  o888    o888   o    o888   o     //
//    o8888oooo88   88ooo88   o8888oooo88 o8888oooo88     //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract CHRS is ERC1155Creator {
    constructor() ERC1155Creator("TO 2022 by GY", "CHRS") {}
}