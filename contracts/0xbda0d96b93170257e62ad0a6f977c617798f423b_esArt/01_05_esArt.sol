// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: etherstu.art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//    ////////////////////////////////////////////////////////////////////    //
//    //                                                                //    //
//    //                                                                //    //
//    //                                                                //    //
//    //                                                                //    //
//    //          _   _                   _                     _       //    //
//    //         | | | |                 | |                   | |      //    //
//    //      ___| |_| |__   ___ _ __ ___| |_ _   _   __ _ _ __| |_     //    //
//    //     / _ \ __| '_ \ / _ \ '__/ __| __| | | | / _` | '__| __|    //    //
//    //    |  __/ |_| | | |  __/ |  \__ \ |_| |_| || (_| | |  | |_     //    //
//    //     \___|\__|_| |_|\___|_|  |___/\__|\__,_(_)__,_|_|   \__|    //    //
//    //                                                                //    //
//    //                                                                //    //
//    //                                                                //    //
//    //                                                                //    //
//    //                                                                //    //
//    //                                                                //    //
//    ////////////////////////////////////////////////////////////////////    //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract esArt is ERC721Creator {
    constructor() ERC721Creator("etherstu.art", "esArt") {}
}