// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: YOKAI ACADEMY-The VOICE SBT-
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                          //
//                                                                                                                                          //
//     /$$     /$$ /$$$$$$  /$$   /$$  /$$$$$$  /$$$$$$        /$$$$$$   /$$$$$$   /$$$$$$  /$$$$$$$  /$$$$$$$$ /$$      /$$ /$$     /$$    //
//    |  $$   /$$//$$__  $$| $$  /$$/ /$$__  $$|_  $$_/       /$$__  $$ /$$__  $$ /$$__  $$| $$__  $$| $$_____/| $$$    /$$$|  $$   /$$/    //
//     \  $$ /$$/| $$  \ $$| $$ /$$/ | $$  \ $$  | $$        | $$  \ $$| $$  \__/| $$  \ $$| $$  \ $$| $$      | $$$$  /$$$$ \  $$ /$$/     //
//      \  $$$$/ | $$  | $$| $$$$$/  | $$$$$$$$  | $$        | $$$$$$$$| $$      | $$$$$$$$| $$  | $$| $$$$$   | $$ $$/$$ $$  \  $$$$/      //
//       \  $$/  | $$  | $$| $$  $$  | $$__  $$  | $$        | $$__  $$| $$      | $$__  $$| $$  | $$| $$__/   | $$  $$$| $$   \  $$/       //
//        | $$   | $$  | $$| $$\  $$ | $$  | $$  | $$        | $$  | $$| $$    $$| $$  | $$| $$  | $$| $$      | $$\  $ | $$    | $$        //
//        | $$   |  $$$$$$/| $$ \  $$| $$  | $$ /$$$$$$      | $$  | $$|  $$$$$$/| $$  | $$| $$$$$$$/| $$$$$$$$| $$ \/  | $$    | $$        //
//        |__/    \______/ |__/  \__/|__/  |__/|______/      |__/  |__/ \______/ |__/  |__/|_______/ |________/|__/     |__/    |__/        //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//     /$$$$$$$$ /$$   /$$ /$$$$$$$$       /$$    /$$  /$$$$$$  /$$$$$$  /$$$$$$  /$$$$$$$$                                                 //
//    |__  $$__/| $$  | $$| $$_____/      | $$   | $$ /$$__  $$|_  $$_/ /$$__  $$| $$_____/                                                 //
//       | $$   | $$  | $$| $$            | $$   | $$| $$  \ $$  | $$  | $$  \__/| $$                                                       //
//       | $$   | $$$$$$$$| $$$$$         |  $$ / $$/| $$  | $$  | $$  | $$      | $$$$$                                                    //
//       | $$   | $$__  $$| $$__/          \  $$ $$/ | $$  | $$  | $$  | $$      | $$__/                                                    //
//       | $$   | $$  | $$| $$              \  $$$/  | $$  | $$  | $$  | $$    $$| $$                                                       //
//       | $$   | $$  | $$| $$$$$$$$         \  $/   |  $$$$$$/ /$$$$$$|  $$$$$$/| $$$$$$$$                                                 //
//       |__/   |__/  |__/|________/          \_/     \______/ |______/ \______/ |________/                                                 //
//                                                                                                                                          //
//                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract YAV is ERC1155Creator {
    constructor() ERC1155Creator("YOKAI ACADEMY-The VOICE SBT-", "YAV") {}
}