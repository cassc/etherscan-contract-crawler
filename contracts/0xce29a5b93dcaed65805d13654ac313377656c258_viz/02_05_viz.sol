// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VIZ OpenEdition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//     ___      ___ ___  ________         //
//    |\  \    /  /|\  \|\_____  \        //
//    \ \  \  /  / | \  \\|___/  /|       //
//     \ \  \/  / / \ \  \   /  / /       //
//      \ \    / /   \ \  \ /  /_/__      //
//       \ \__/ /     \ \__\\________\    //
//        \|__|/       \|__|\|_______|    //
//                                        //
//                                        //
//                                        //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract viz is ERC721Creator {
    constructor() ERC721Creator("VIZ OpenEdition", "viz") {}
}