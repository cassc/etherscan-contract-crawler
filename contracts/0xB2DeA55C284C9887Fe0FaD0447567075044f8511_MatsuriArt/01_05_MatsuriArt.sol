// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Matsuri Art
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//                                                             //
//      __  __       _                  _    _         _       //
//     |  \/  | __ _| |_ ___ _   _ _ __(_)  / \   _ __| |_     //
//     | |\/| |/ _` | __/ __| | | | '__| | / _ \ | '__| __|    //
//     | |  | | (_| | |_\__ \ |_| | |  | |/ ___ \| |  | |_     //
//     |_|  |_|\__,_|\__|___/\__,_|_|  |_/_/   \_\_|   \__|    //
//                                                             //
//                                                             //
//                                                             //
//                                                             //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract MatsuriArt is ERC1155Creator {
    constructor() ERC1155Creator("Matsuri Art", "MatsuriArt") {}
}