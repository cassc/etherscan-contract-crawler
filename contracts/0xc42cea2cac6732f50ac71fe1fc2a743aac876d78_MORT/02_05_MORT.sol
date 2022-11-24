// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mort's Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                                               //
//     ▄▀▀▄ ▄▀▄  ▄▀▀▀▀▄   ▄▀▀▄▀▀▀▄  ▄▀▀▀█▀▀▄     //
//    █  █ ▀  █ █      █ █   █   █ █    █  ▐     //
//    ▐  █    █ █      █ ▐  █▀▀█▀  ▐   █         //
//      █    █  ▀▄    ▄▀  ▄▀    █     █          //
//    ▄▀   ▄▀     ▀▀▀▀   █     █    ▄▀           //
//    █    █             ▐     ▐   █             //
//    ▐    ▐                       ▐             //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract MORT is ERC1155Creator {
    constructor() ERC1155Creator() {}
}