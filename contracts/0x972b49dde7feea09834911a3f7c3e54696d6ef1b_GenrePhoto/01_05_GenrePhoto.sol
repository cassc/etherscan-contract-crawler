// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bager Genre Photography
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//                                                                                  //
//     _____                                                                        //
//    |  __ \                                                                       //
//    | |  \/  ___  _ __   _ __   ___                                               //
//    | | __  / _ \| '_ \ | '__| / _ \                                              //
//    | |_\ \|  __/| | | || |   |  __/                                              //
//     \____/ \___||_| |_||_|    \___|                                              //
//                                                                                  //
//                                                                                  //
//    ______  _             _                                      _                //
//    | ___ \| |           | |                                    | |               //
//    | |_/ /| |__    ___  | |_   ___    __ _  _ __   __ _  _ __  | |__   _   _     //
//    |  __/ | '_ \  / _ \ | __| / _ \  / _` || '__| / _` || '_ \ | '_ \ | | | |    //
//    | |    | | | || (_) || |_ | (_) || (_| || |   | (_| || |_) || | | || |_| |    //
//    \_|    |_| |_| \___/  \__| \___/  \__, ||_|    \__,_|| .__/ |_| |_| \__, |    //
//                                       __/ |             | |             __/ |    //
//                                      |___/              |_|            |___/     //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////


contract GenrePhoto is ERC721Creator {
    constructor() ERC721Creator("Bager Genre Photography", "GenrePhoto") {}
}