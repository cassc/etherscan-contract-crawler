// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DnDJourneyPass
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//             _                                              //
//     ____  _| |_ ____        __                             //
//    |    \|   __|    \    __|  |___ _ _ ___ ___ ___ _ _     //
//    |  |  |   __|  |  |  |  |  | . | | |  _|   | -_| | |    //
//    |____/|_   _|____/   |_____|___|___|_| |_|_|___|_  |    //
//            |_|                                    |___|    //
//                                                            //
//    By Annihilap.eth                                        //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract DJP is ERC1155Creator {
    constructor() ERC1155Creator("DnDJourneyPass", "DJP") {}
}