// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alison's Amayzing Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//       ___,   _                      o       ___                                     //
//      /   |  | | o                   /      / (_)   |  o     o                       //
//     |    |  | |     ,   __   _  _     ,    \__   __|    _|_     __   _  _    ,      //
//     |    |  |/  |  / \_/  \_/ |/ |   / \_  /    /  |  |  |  |  /  \_/ |/ |  / \_    //
//      \__/\_/|__/|_/ \/ \__/   |  |_/  \/   \___/\_/|_/|_/|_/|_/\__/   |  |_/ \/     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract EditionsbyAlison is ERC1155Creator {
    constructor() ERC1155Creator("Alison's Amayzing Editions", "EditionsbyAlison") {}
}