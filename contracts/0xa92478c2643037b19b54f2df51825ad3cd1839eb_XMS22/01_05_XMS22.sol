// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fake Fake Rare Holiday Card 2022
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                       //
//                                                                                                                                                                                                                                       //
//                                                                                                                                                                                                                                       //
//     _______                               _______         __ __     __                         ______ ______ ______ ______          ___                           _______                         ______                              //
//    |   |   |.---.-.-----.-----.--.--.    |   |   |.-----.|  |__|.--|  |.---.-.--.--.-----.    |__    |      |__    |__    |       .'  _|.----.-----.--------.    |    |  |.-----.--.--.-----.    |   __ \.-----.-----.-----.-----.    //
//    |       ||  _  |  _  |  _  |  |  |    |       ||  _  ||  |  ||  _  ||  _  |  |  |__ --|    |    __|  --  |    __|    __|__     |   _||   _|  _  |        |    |       ||  _  |  |  |     |    |    __/|  -__|  _  |  -__|__ --|    //
//    |___|___||___._|   __|   __|___  |    |___|___||_____||__|__||_____||___._|___  |_____|    |______|______|______|______|  |    |__|  |__| |_____|__|__|__|    |__|____||_____|_____|__|__|    |___|   |_____|   __|_____|_____|    //
//                   |__|  |__|  |_____|                                        |_____|                                       |_|                                                                                 |__|                   //
//                                                                                                                                                                                                                                       //
//                                                                                                                                                                                                                                       //
//                                                                                                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract XMS22 is ERC721Creator {
    constructor() ERC721Creator("Fake Fake Rare Holiday Card 2022", "XMS22") {}
}