// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Yosemite Through The Seasons
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
//                                                                                 //
//                                                                                 //
//              __   __                       _ _                                  //
//              \ \ / /__  ___  ___ _ __ ___ (_) |_ ___                            //
//               \ V / _ \/ __|/ _ \ '_ ` _ \| | __/ _ \                           //
//                | | (_) \__ \  __/ | | | | | | ||  __/                           //
//           _____|_|\___/|___/\___|_| |_| |_|_|\__\___|____ _                     //
//          |_   _| |__  _ __ ___  _   _  __ _| |__   |_   _| |__   ___            //
//            | | | '_ \| '__/ _ \| | | |/ _` | '_ \    | | | '_ \ / _ \           //
//            | | | | | | | | (_) | |_| | (_| | | | |   | | | | | |  __/           //
//            |_| |_|_|_|_|  \___/ \__,_|\__, |_| |_|   |_| |_| |_|\___|           //
//                / ___|  ___  __ _ ___  |___/_ __  ___                            //
//                \___ \ / _ \/ _` / __|/ _ \| '_ \/ __|                           //
//                 ___) |  __/ (_| \__ \ (_) | | | \__ \                           //
//                |____/ \___|\__,_|___/\___/|_| |_|___/                           //
//                                                                                 //
//                                       /\                                        //
//                                  /\  //\\                                       //
//                           /\    //\\///\\\        /\                            //
//                          //\\  ///\////\\\\  /\  //\\                           //
//             /\          /  ^ \/^ ^/^  ^  ^ \/^ \/  ^ \                          //
//            / ^\    /\  / ^   /  ^/ ^ ^ ^   ^\ ^/  ^^  \                         //
//           /^   \  / ^\/ ^ ^   ^ / ^  ^    ^  \/ ^   ^  \       *                //
//          /  ^ ^ \/^  ^\ ^ ^ ^   ^  ^   ^   ____  ^   ^  \     /|\               //
//         / ^ ^  ^ \ ^  _\___________________|  |_____^ ^  \   /||o\              //
//        / ^^  ^ ^ ^\  /______________________________\ ^ ^ \ /|o|||\             //
//       /  ^  ^^ ^ ^  /________________________________\  ^  /|||||o|\            //
//      /^ ^  ^ ^^  ^    ||___|___||||||||||||___|__|||      /||o||||||\           //
//     / ^   ^   ^    ^  ||___|___||||||||||||___|__|||          | |               //
//    / ^ ^ ^  ^  ^  ^   ||||||||||||||||||||||||||||||oooooooooo| |ooooooo        //
//    ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo        //
//                                                                                 //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////


contract YOS is ERC721Creator {
    constructor() ERC721Creator("Yosemite Through The Seasons", "YOS") {}
}