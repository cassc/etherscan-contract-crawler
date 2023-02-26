// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ABYSS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//      ___  ________   _______ _____                      //
//     / _ \ | ___ \ \ / /  ___/  ___|                     //
//    / /_\ \| |_/ /\ V /\ `--.\ `--.                      //
//    |  _  || ___ \ \ /  `--. \`--. \                     //
//    | | | || |_/ / | | /\__/ /\__/ /                     //
//    \_| |_/\____/  \_/ \____/\____/   BY NADINE BAUER    //
//                                                         //
//                                                         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract DARK is ERC721Creator {
    constructor() ERC721Creator("ABYSS", "DARK") {}
}