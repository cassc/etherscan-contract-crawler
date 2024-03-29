// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cexeletons
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//     ▄████▄  ▓█████ ▒██   ██▒▓█████  ██▓    ▓█████▄▄▄█████▓ ▒█████   ███▄    █   ██████     //
//    ▒██▀ ▀█  ▓█   ▀ ▒▒ █ █ ▒░▓█   ▀ ▓██▒    ▓█   ▀▓  ██▒ ▓▒▒██▒  ██▒ ██ ▀█   █ ▒██    ▒     //
//    ▒▓█    ▄ ▒███   ░░  █   ░▒███   ▒██░    ▒███  ▒ ▓██░ ▒░▒██░  ██▒▓██  ▀█ ██▒░ ▓██▄       //
//    ▒▓▓▄ ▄██▒▒▓█  ▄  ░ █ █ ▒ ▒▓█  ▄ ▒██░    ▒▓█  ▄░ ▓██▓ ░ ▒██   ██░▓██▒  ▐▌██▒  ▒   ██▒    //
//    ▒ ▓███▀ ░░▒████▒▒██▒ ▒██▒░▒████▒░██████▒░▒████▒ ▒██▒ ░ ░ ████▓▒░▒██░   ▓██░▒██████▒▒    //
//    ░ ░▒ ▒  ░░░ ▒░ ░▒▒ ░ ░▓ ░░░ ▒░ ░░ ▒░▓  ░░░ ▒░ ░ ▒ ░░   ░ ▒░▒░▒░ ░ ▒░   ▒ ▒ ▒ ▒▓▒ ▒ ░    //
//      ░  ▒    ░ ░  ░░░   ░▒ ░ ░ ░  ░░ ░ ▒  ░ ░ ░  ░   ░      ░ ▒ ▒░ ░ ░░   ░ ▒░░ ░▒  ░ ░    //
//    ░           ░    ░    ░     ░     ░ ░      ░    ░      ░ ░ ░ ▒     ░   ░ ░ ░  ░  ░      //
//    ░ ░         ░  ░ ░    ░     ░  ░    ░  ░   ░  ░            ░ ░           ░       ░      //
//    ░                                                                                       //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract CXLTN is ERC721Creator {
    constructor() ERC721Creator("Cexeletons", "CXLTN") {}
}