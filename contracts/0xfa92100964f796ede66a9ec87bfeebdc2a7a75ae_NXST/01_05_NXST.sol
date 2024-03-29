// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: INEXHAUSTIBLE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                               //
//                                                                                                               //
//     ██▓ ███▄    █ ▓█████ ▒██   ██▒ ██░ ██  ▄▄▄       █    ██   ██████ ▄▄▄█████▓ ██▓ ▄▄▄▄    ██▓    ▓█████     //
//    ▓██▒ ██ ▀█   █ ▓█   ▀ ▒▒ █ █ ▒░▓██░ ██▒▒████▄     ██  ▓██▒▒██    ▒ ▓  ██▒ ▓▒▓██▒▓█████▄ ▓██▒    ▓█   ▀     //
//    ▒██▒▓██  ▀█ ██▒▒███   ░░  █   ░▒██▀▀██░▒██  ▀█▄  ▓██  ▒██░░ ▓██▄   ▒ ▓██░ ▒░▒██▒▒██▒ ▄██▒██░    ▒███       //
//    ░██░▓██▒  ▐▌██▒▒▓█  ▄  ░ █ █ ▒ ░▓█ ░██ ░██▄▄▄▄██ ▓▓█  ░██░  ▒   ██▒░ ▓██▓ ░ ░██░▒██░█▀  ▒██░    ▒▓█  ▄     //
//    ░██░▒██░   ▓██░░▒████▒▒██▒ ▒██▒░▓█▒░██▓ ▓█   ▓██▒▒▒█████▓ ▒██████▒▒  ▒██▒ ░ ░██░░▓█  ▀█▓░██████▒░▒████▒    //
//    ░▓  ░ ▒░   ▒ ▒ ░░ ▒░ ░▒▒ ░ ░▓ ░ ▒ ░░▒░▒ ▒▒   ▓▒█░░▒▓▒ ▒ ▒ ▒ ▒▓▒ ▒ ░  ▒ ░░   ░▓  ░▒▓███▀▒░ ▒░▓  ░░░ ▒░ ░    //
//     ▒ ░░ ░░   ░ ▒░ ░ ░  ░░░   ░▒ ░ ▒ ░▒░ ░  ▒   ▒▒ ░░░▒░ ░ ░ ░ ░▒  ░ ░    ░     ▒ ░▒░▒   ░ ░ ░ ▒  ░ ░ ░  ░    //
//     ▒ ░   ░   ░ ░    ░    ░    ░   ░  ░░ ░  ░   ▒    ░░░ ░ ░ ░  ░  ░    ░       ▒ ░ ░    ░   ░ ░      ░       //
//     ░           ░    ░  ░ ░    ░   ░  ░  ░      ░  ░   ░           ░            ░   ░          ░  ░   ░  ░    //
//                                                                                          ░                    //
//    By: Avi900                                                                                                 //
//                                                                                                               //
//                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NXST is ERC721Creator {
    constructor() ERC721Creator("INEXHAUSTIBLE", "NXST") {}
}