// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SUMMER STATE OF MIND
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                    //
//                                                                                                                                    //
//     /$$$$$$$ /$$   /$$ /$$$$$$/$$$$  /$$$$$$/$$$$   /$$$$$$   /$$$$$$         /$$$$$$$ /$$$$$$    /$$$$$$  /$$$$$$    /$$$$$$      //
//     /$$_____/| $$  | $$| $$_  $$_  $$| $$_  $$_  $$ /$$__  $$ /$$__  $$       /$$_____/|_  $$_/   |____  $$|_  $$_/   /$$__  $$    //
//    |  $$$$$$ | $$  | $$| $$ \ $$ \ $$| $$ \ $$ \ $$| $$$$$$$$| $$  \__/      |  $$$$$$   | $$      /$$$$$$$  | $$    | $$$$$$$$    //
//     \____  $$| $$  | $$| $$ | $$ | $$| $$ | $$ | $$| $$_____/| $$             \____  $$  | $$ /$$ /$$__  $$  | $$ /$$| $$_____/    //
//     /$$$$$$$/|  $$$$$$/| $$ | $$ | $$| $$ | $$ | $$|  $$$$$$$| $$             /$$$$$$$/  |  $$$$/|  $$$$$$$  |  $$$$/|  $$$$$$$    //
//    |_______/  \______/ |__/ |__/ |__/|__/ |__/ |__/ \_______/|__/            |_______/    \___/   \_______/   \___/   \_______/    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                /$$$$$$                                                                                                             //
//               /$$__  $$                                                                                                            //
//      /$$$$$$ | $$  \__/                                                                                                            //
//     /$$__  $$| $$$$                                                                                                                //
//    | $$  \ $$| $$_/                                                                                                                //
//    | $$  | $$| $$                                                                                                                  //
//    |  $$$$$$/| $$                                                                                                                  //
//     \______/ |__/                                                                                                                  //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                   /$$                 /$$                                                                                          //
//                  |__/                | $$                                                                                          //
//     /$$$$$$/$$$$  /$$ /$$$$$$$   /$$$$$$$                                                                                          //
//    | $$_  $$_  $$| $$| $$__  $$ /$$__  $$                                                                                          //
//    | $$ \ $$ \ $$| $$| $$  \ $$| $$  | $$                                                                                          //
//    | $$ | $$ | $$| $$| $$  | $$| $$  | $$                                                                                          //
//    | $$ | $$ | $$| $$| $$  | $$|  $$$$$$$                                                                                          //
//    |__/ |__/ |__/|__/|__/  |__/ \_______/                                                                                          //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SUM is ERC721Creator {
    constructor() ERC721Creator("SUMMER STATE OF MIND", "SUM") {}
}