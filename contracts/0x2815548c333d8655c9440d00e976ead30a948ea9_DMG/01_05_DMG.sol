// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Damage
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//     ██▄   ██   █▀▄▀█ ██     ▄▀  ▄███▄       //
//    █  █  █ █  █ █ █ █ █  ▄▀    █▀   ▀       //
//    █   █ █▄▄█ █ ▄ █ █▄▄█ █ ▀▄  ██▄▄         //
//    █  █  █  █ █   █ █  █ █   █ █▄   ▄▀      //
//    ███▀     █    █     █  ███  ▀███▀        //
//            █    ▀     █                     //
//           ▀          ▀                      //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract DMG is ERC1155Creator {
    constructor() ERC1155Creator("Damage", "DMG") {}
}