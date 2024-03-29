// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Possidere
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//                                                                                //
//    ______  _______  ______                                                     //
//    (  ____ )(  ____ \(  __  \                                                  //
//    | (    )|| (    \/| (  \  )                                                 //
//    | (____)|| (_____ | |   ) |                                                 //
//    |  _____)(_____  )| |   | |                                                 //
//    | (            ) || |   ) |                                                 //
//    | )      /\____) || (__/  )                                                 //
//    |/       \_______)(______/                                                  //
//                                                                                //
//     ______   ______   _       _________ _       _________ _______              //
//    / ___  \ (  __  \ ( (    /|\__   __/( (    /|\__    _/(  ___  )|\     /|    //
//    \/   \  \| (  \  )|  \  ( |   ) (   |  \  ( |   )  (  | (   ) || )   ( |    //
//       ___) /| |   ) ||   \ | |   | |   |   \ | |   |  |  | (___) || (___) |    //
//      (___ ( | |   | || (\ \) |   | |   | (\ \) |   |  |  |  ___  ||  ___  |    //
//          ) \| |   ) || | \   |   | |   | | \   |   |  |  | (   ) || (   ) |    //
//    /\___/  /| (__/  )| )  \  |___) (___| )  \  ||\_)  )  | )   ( || )   ( |    //
//    \______/ (______/ |/    )_)\_______/|/    )_)(____/   |/     \||/     \|    //
//                                                                                //
//     _______  _______  _______  ______                                          //
//    / ___   )(  __   )/ ___   )/ ___  \                                         //
//    \/   )  || (  )  |\/   )  |\/   \  \                                        //
//        /   )| | /   |    /   )   ___) /                                        //
//      _/   / | (/ /) |  _/   /   (___ (                                         //
//     /   _/  |   / | | /   _/        ) \                                        //
//    (   (__/\|  (__) |(   (__/\/\___/  /                                        //
//    \_______/(_______)\_______/\______/                                         //
//                                                                                //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////


contract PSD is ERC721Creator {
    constructor() ERC721Creator("Possidere", "PSD") {}
}