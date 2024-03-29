// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JORDIGANDUL.1155
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//        ___          ___           ___          _____                                       //
//       /  /\        /  /\         /  /\        /  /::\       ___                            //
//      /  /:/       /  /::\       /  /::\      /  /:/\:\     /  /\                           //
//     /__/::\      /  /:/\:\     /  /:/\:\    /  /:/  \:\   /  /:/                           //
//     \__\/\:\    /  /:/  \:\   /  /:/~/:/   /__/:/ \__\:| /__/::\                           //
//        \  \:\  /__/:/ \__\:\ /__/:/ /:/___ \  \:\ /  /:/ \__\/\:\__                        //
//         \__\:\ \  \:\ /  /:/ \  \:\/:::::/  \  \:\  /:/     \  \:\/\                       //
//         /  /:/  \  \:\  /:/   \  \::/~~~~    \  \:\/:/       \__\::/                       //
//        /__/:/    \  \:\/:/     \  \:\         \  \::/        /__/:/                        //
//        \__\/      \  \::/       \  \:\         \__\/         \__\/                         //
//                    \__\/         \__\/                                                     //
//          ___           ___           ___          _____          ___                       //
//         /  /\         /  /\         /__/\        /  /::\        /__/\                      //
//        /  /:/_       /  /::\        \  \:\      /  /:/\:\       \  \:\                     //
//       /  /:/ /\     /  /:/\:\        \  \:\    /  /:/  \:\       \  \:\    ___     ___     //
//      /  /:/_/::\   /  /:/~/::\   _____\__\:\  /__/:/ \__\:|  ___  \  \:\  /__/\   /  /\    //
//     /__/:/__\/\:\ /__/:/ /:/\:\ /__/::::::::\ \  \:\ /  /:/ /__/\  \__\:\ \  \:\ /  /:/    //
//     \  \:\ /~~/:/ \  \:\/:/__\/ \  \:\~~\~~\/  \  \:\  /:/  \  \:\ /  /:/  \  \:\  /:/     //
//      \  \:\  /:/   \  \::/       \  \:\  ~~~    \  \:\/:/    \  \:\  /:/    \  \:\/:/      //
//       \  \:\/:/     \  \:\        \  \:\         \  \::/      \  \:\/:/      \  \::/       //
//        \  \::/       \  \:\        \  \:\         \__\/        \  \::/        \__\/        //
//         \__\/         \__\/         \__\/                       \__\/                      //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract GNDL is ERC1155Creator {
    constructor() ERC1155Creator("JORDIGANDUL.1155", "GNDL") {}
}