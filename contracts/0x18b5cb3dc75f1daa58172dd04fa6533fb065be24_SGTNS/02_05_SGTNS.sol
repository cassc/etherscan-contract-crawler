// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Suggestions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//      ██████  █    ██   ▄████   ▄████ ▓█████   ██████ ▄▄▄█████▓ ██▓ ▒█████   ███▄    █   ██████     //
//    ▒██    ▒  ██  ▓██▒ ██▒ ▀█▒ ██▒ ▀█▒▓█   ▀ ▒██    ▒ ▓  ██▒ ▓▒▓██▒▒██▒  ██▒ ██ ▀█   █ ▒██    ▒     //
//    ░ ▓██▄   ▓██  ▒██░▒██░▄▄▄░▒██░▄▄▄░▒███   ░ ▓██▄   ▒ ▓██░ ▒░▒██▒▒██░  ██▒▓██  ▀█ ██▒░ ▓██▄       //
//      ▒   ██▒▓▓█  ░██░░▓█  ██▓░▓█  ██▓▒▓█  ▄   ▒   ██▒░ ▓██▓ ░ ░██░▒██   ██░▓██▒  ▐▌██▒  ▒   ██▒    //
//    ▒██████▒▒▒▒█████▓ ░▒▓███▀▒░▒▓███▀▒░▒████▒▒██████▒▒  ▒██▒ ░ ░██░░ ████▓▒░▒██░   ▓██░▒██████▒▒    //
//    ▒ ▒▓▒ ▒ ░░▒▓▒ ▒ ▒  ░▒   ▒  ░▒   ▒ ░░ ▒░ ░▒ ▒▓▒ ▒ ░  ▒ ░░   ░▓  ░ ▒░▒░▒░ ░ ▒░   ▒ ▒ ▒ ▒▓▒ ▒ ░    //
//    ░ ░▒  ░ ░░░▒░ ░ ░   ░   ░   ░   ░  ░ ░  ░░ ░▒  ░ ░    ░     ▒ ░  ░ ▒ ▒░ ░ ░░   ░ ▒░░ ░▒  ░ ░    //
//    ░  ░  ░   ░░░ ░ ░ ░ ░   ░ ░ ░   ░    ░   ░  ░  ░    ░       ▒ ░░ ░ ░ ▒     ░   ░ ░ ░  ░  ░      //
//          ░     ░           ░       ░    ░  ░      ░            ░      ░ ░           ░       ░      //
//                                                                                                    //
//    “Suggestions” (2022) is a set from the series “Detremura” (2019-),                              //
//    by Pedro Victor Brandão. The works were commissioned for the exhibition                         //
//    “Non-Fungible Castle 2022: Preserving Culture On The Blockchain”,                               //
//    curated by Jake Al-Haffar at the Lobkowicz Palace in Prague, Czech Republic,                    //
//    from October 27 to November 13, 2022.                                                           //
//                                                                                                    //
//                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SGTNS is ERC721Creator {
    constructor() ERC721Creator("Suggestions", "SGTNS") {}
}