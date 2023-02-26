// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BABY
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//           .' '.            //
//      __  /     \   _       //
//     /.-;|  /'._|_.'#`\     //
//    ||   |  |  _       |    //
//    \\__/|  \.' ;'-.__/     //
//     '--' \     /           //
//           '._.'            //
//                            //
//                            //
////////////////////////////////


contract BAE is ERC1155Creator {
    constructor() ERC1155Creator("BABY", "BAE") {}
}