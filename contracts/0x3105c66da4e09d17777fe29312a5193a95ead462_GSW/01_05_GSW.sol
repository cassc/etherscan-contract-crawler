// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GSW Originals //
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
//          ___ ___                                                                                               //
//         /  //  /|                                                                                              //
//        /  //  //                                                                                               //
//       /  //  //                                                                                                //
//      /  //  //                                                                                                 //
//     /_ //_ //                                                                                                  //
//    |__|/__|/                                                                                                   //
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
//     ________  ________  ___       __                ___ ___                                                    //
//    |\   ____\|\   ____\|\  \     |\  \             /  //  /|                                                   //
//    \ \  \___|\ \  \___|\ \  \    \ \  \           /  //  //                                                    //
//     \ \  \  __\ \_____  \ \  \  __\ \  \         /  //  //                                                     //
//      \ \  \|\  \|____|\  \ \  \|\__\_\  \       /  //  //                                                      //
//       \ \_______\____\_\  \ \____________\     /_ //_ //                                                       //
//        \|_______|\_________\|____________|    |__|/__|/                                                        //
//                 \|_________|                                                                                   //
//                                                                                                                //
//                                                                                                                //
//     ________  ________  ___  ________  ___  ________   ________  ___       ________                ___ ___     //
//    |\   __  \|\   __  \|\  \|\   ____\|\  \|\   ___  \|\   __  \|\  \     |\   ____\              /  //  /|    //
//    \ \  \|\  \ \  \|\  \ \  \ \  \___|\ \  \ \  \\ \  \ \  \|\  \ \  \    \ \  \___|_            /  //  //     //
//     \ \  \\\  \ \   _  _\ \  \ \  \  __\ \  \ \  \\ \  \ \   __  \ \  \    \ \_____  \          /  //  //      //
//      \ \  \\\  \ \  \\  \\ \  \ \  \|\  \ \  \ \  \\ \  \ \  \ \  \ \  \____\|____|\  \        /  //  //       //
//       \ \_______\ \__\\ _\\ \__\ \_______\ \__\ \__\\ \__\ \__\ \__\ \_______\____\_\  \      /_ //_ //        //
//        \|_______|\|__|\|__|\|__|\|_______|\|__|\|__| \|__|\|__|\|__|\|_______|\_________\    |__|/__|/         //
//                                                                              \|_________|                      //
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GSW is ERC721Creator {
    constructor() ERC721Creator("GSW Originals //", "GSW") {}
}