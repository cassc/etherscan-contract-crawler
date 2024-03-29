// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lamu Life
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//                                                            //
//     ▄            ▄▄▄▄▄▄▄▄▄▄▄  ▄▄       ▄▄  ▄         ▄     //
//    ▐░▌          ▐░░░░░░░░░░░▌▐░░▌     ▐░░▌▐░▌       ▐░▌    //
//    ▐░▌          ▐░█▀▀▀▀▀▀▀█░▌▐░▌░▌   ▐░▐░▌▐░▌       ▐░▌    //
//    ▐░▌          ▐░▌       ▐░▌▐░▌▐░▌ ▐░▌▐░▌▐░▌       ▐░▌    //
//    ▐░▌          ▐░█▄▄▄▄▄▄▄█░▌▐░▌ ▐░▐░▌ ▐░▌▐░▌       ▐░▌    //
//    ▐░▌          ▐░░░░░░░░░░░▌▐░▌  ▐░▌  ▐░▌▐░▌       ▐░▌    //
//    ▐░▌          ▐░█▀▀▀▀▀▀▀█░▌▐░▌   ▀   ▐░▌▐░▌       ▐░▌    //
//    ▐░▌          ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌    //
//    ▐░█▄▄▄▄▄▄▄▄▄ ▐░▌       ▐░▌▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄█░▌    //
//    ▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌    //
//     ▀▀▀▀▀▀▀▀▀▀▀  ▀         ▀  ▀         ▀  ▀▀▀▀▀▀▀▀▀▀▀     //
//                                                            //
//     ▄            ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄     //
//    ▐░▌          ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌    //
//    ▐░▌           ▀▀▀▀█░█▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀     //
//    ▐░▌               ▐░▌     ▐░▌          ▐░▌              //
//    ▐░▌               ▐░▌     ▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄▄▄     //
//    ▐░▌               ▐░▌     ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌    //
//    ▐░▌               ▐░▌     ▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀     //
//    ▐░▌               ▐░▌     ▐░▌          ▐░▌              //
//    ▐░█▄▄▄▄▄▄▄▄▄  ▄▄▄▄█░█▄▄▄▄ ▐░▌          ▐░█▄▄▄▄▄▄▄▄▄     //
//    ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌          ▐░░░░░░░░░░░▌    //
//     ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀            ▀▀▀▀▀▀▀▀▀▀▀     //
//                                                            //
//                                                            //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract Lamu is ERC721Creator {
    constructor() ERC721Creator("Lamu Life", "Lamu") {}
}