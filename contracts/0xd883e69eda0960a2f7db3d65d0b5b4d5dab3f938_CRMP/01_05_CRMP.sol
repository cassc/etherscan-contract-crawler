// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Crimson Portrait
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    ▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄       //
//    ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌    //
//    ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀▀▀     //
//    ▐░▌       ▐░▌▐░▌              //
//    ▐░▌       ▐░▌▐░▌              //
//    ▐░▌       ▐░▌▐░▌              //
//    ▐░▌       ▐░▌▐░▌              //
//    ▐░▌       ▐░▌▐░▌              //
//    ▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄▄▄     //
//    ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌    //
//                                  //
//                                  //
//////////////////////////////////////


contract CRMP is ERC1155Creator {
    constructor() ERC1155Creator("Crimson Portrait", "CRMP") {}
}