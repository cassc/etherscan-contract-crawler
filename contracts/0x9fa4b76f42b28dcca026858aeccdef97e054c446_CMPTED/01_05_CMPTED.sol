// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Complicit Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//     .--.                 .              .         //
//    :                     |   o       o _|_        //
//    |    .-. .--.--. .,-. |   .  .-.  .  |         //
//    :   (   )|  |  | |   )|   | (     |  |         //
//     `--'`-' '  '  `-|`-' `--' `-`-'-' `-`-'       //
//    .---.   .      . |                             //
//    |       |   o _|_'  o                          //
//    |--- .-.|   .  |    .  .-. .--. .--.           //
//    |   (   |   |  |    | (   )|  | `--.           //
//    '---'`-'`--' `-`-'-' `-`-' '  `-`--'           //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract CMPTED is ERC1155Creator {
    constructor() ERC1155Creator("Complicit Editions", "CMPTED") {}
}