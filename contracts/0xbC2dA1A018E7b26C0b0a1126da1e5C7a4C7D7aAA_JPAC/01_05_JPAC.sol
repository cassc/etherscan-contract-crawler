// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Julien Pacaud
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//                                       //
//                 _          _          //
//                /\ \       /\ \        //
//                \ \ \     /  \ \       //
//                /\ \_\   / /\ \ \      //
//               / /\/_/  / / /\ \_\     //
//      _       / / /    / / /_/ / /     //
//     /\ \    / / /    / / /__\/ /      //
//     \ \_\  / / /    / / /_____/       //
//     / / /_/ / /_   / / /_             //
//    / / /__\/ //\_\/ / //\_\           //
//    \/_______/ \/_/\/_/ \/_/           //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract JPAC is ERC721Creator {
    constructor() ERC721Creator("Julien Pacaud", "JPAC") {}
}