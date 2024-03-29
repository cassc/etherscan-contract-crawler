// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Milady Bikini
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                       //
//                                                                                                       //
//       _____  .___.____       _____  ________ _____.___. __________.___ ____  __.___ _______  .___     //
//      /     \ |   |    |     /  _  \ \______ \\__  |   | \______   \   |    |/ _|   |\      \ |   |    //
//     /  \ /  \|   |    |    /  /_\  \ |    |  \/   |   |  |    |  _/   |      < |   |/   |   \|   |    //
//    /    Y    \   |    |___/    |    \|    `   \____   |  |    |   \   |    |  \|   /    |    \   |    //
//    \____|__  /___|_______ \____|__  /_______  / ______|  |______  /___|____|__ \___\____|__  /___|    //
//            \/            \/       \/        \/\/                \/            \/           \/         //
//                                                                                                       //
//                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Pepeswim is ERC1155Creator {
    constructor() ERC1155Creator("Milady Bikini", "Pepeswim") {}
}