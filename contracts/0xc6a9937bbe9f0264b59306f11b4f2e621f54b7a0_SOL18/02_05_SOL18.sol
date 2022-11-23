// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Seconds of Life - Gone Real
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//       _____                          _              __   _      _  __               //
//      / ____|                        | |            / _| | |    (_)/ _|              //
//     | (___   ___  ___ ___  _ __   __| |___    ___ | |_  | |     _| |_ ___           //
//      \___ \ / _ \/ __/ _ \| '_ \ / _` / __|  / _ \|  _| | |    | |  _/ _ \          //
//      ____) |  __/ (_| (_) | | | | (_| \__ \ | (_) | |   | |____| | ||  __/          //
//     |_____/ \___|\___\___/|_| |_|\__,_|___/  \___/|_|   |______|_|_| \___|          //
//      / ____|                  |  __ \          | |                                  //
//     | |  __  ___  _ __   ___  | |__) |___  __ _| |                                  //
//     | | |_ |/ _ \| '_ \ / _ \ |  _  // _ \/ _` | |                                  //
//     | |__| | (_) | | | |  __/ | | \ \  __/ (_| | |                                  //
//      \_____|\___/|_| |_|\___| |_|  \_\___|\__,_|_|                                  //
//                                                                                     //
//                                                                                     //
//    The following edition is an effort to give back to the primary collectors        //
//    who have supported me (Ilan Derech), and my art collection "Seconds of Life".    //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract SOL18 is ERC721Creator {
    constructor() ERC721Creator("Seconds of Life - Gone Real", "SOL18") {}
}