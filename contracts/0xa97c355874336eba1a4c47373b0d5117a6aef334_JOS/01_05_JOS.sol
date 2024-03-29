// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jos Vromans
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                  //
//                                                                                                                                                  //
//    ======================================================================================================                                        //
//            ____                       _           _                      _       _                                                               //
//           / __ \                     | |         (_)                    | |     | |                                                              //
//          | |  | |_ __    _____    ___| |__   __ _ _ _ __       __ _ _ __| |_    | |__  _   _                                                     //
//          | |  | | '_ \  |_____|  / __| '_ \ / _` | | '_ \     / _` | '__| __|   | '_ \| | | |                                                    //
//          | |__| | | | |         | (__| | | | (_| | | | | |   | (_| | |  | |_    | |_) | |_| |                                                    //
//           \____/|_| |_|          \___|_| |_|\__,_|_|_| |_|    \__,_|_|   \__|   |_.__/ \__, |                                                    //
//                                                                                         __/ |                                                    //
//                                                                                        |___/                                                     //
//                _               __      __                                                                                                        //
//               | |              \ \    / /                                                                                                        //
//               | | ___  ___      \ \  / / __ ___  _ __ ___   __ _ _ __  ___                                                                       //
//           _   | |/ _ \/ __|      \ \/ / '__/ _ \| '_ ` _ \ / _` | '_ \/ __|                                                                      //
//          | |__| | (_) \__ \       \  /| | | (_) | | | | | | (_| | | | \__ \                                                                      //
//           \____/ \___/|___/        \/ |_|  \___/|_| |_| |_|\__,_|_| |_|___/                                                                      //
//                                                                                                                                                  //
//    ================================================================ vromance.eth / www.josvromans.com ===                                        //
//                                                                                                                                                  //
//                                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JOS is ERC721Creator {
    constructor() ERC721Creator("Jos Vromans", "JOS") {}
}