// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RYDEN EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//     ______     __  __        //
//    /\  == \   /\ \_\ \       //
//    \ \  __<   \ \____ \      //
//     \ \_\ \_\  \/\_____\     //
//      \/_/ /_/   \/_____/     //
//                              //
//                              //
//                              //
//////////////////////////////////


contract RY is ERC1155Creator {
    constructor() ERC1155Creator("RYDEN EDITIONS", "RY") {}
}