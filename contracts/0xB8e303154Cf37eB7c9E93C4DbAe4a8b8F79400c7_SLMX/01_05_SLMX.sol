// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SOULIMMIX
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//     ░░░░░░░░░░░░░░░░░░░░░░░░░░▒░           ░▒░░░░░░░░░░░░░░░░░░░    //
//     ░░░░░░░░░░░░░░▒░░░░░░░░░▒░                ░▒░░░░░░░░░░░░░░░░    //
//     ░░░░░░░░░░░░░▓▓▒░░░░░░░░              ▄▓    ░░░░░░░░░░░░░░░░    //
//     ░░░░░░░░░░░░░▓▓▌░░░░░░░░             ▓▓▌    ░▒░░░░░░░░░░░░░░    //
//     ░░░░░▓░░░░░░░▓▓▓░░░░░▒░░░           ▓▓▌      ░░░░░░░░░░░░░░░    //
//     ░░▐▒░█▒░░░░░░▓▓▓░░░░░▒░░░          ▓▓▌      ░░▒░░░░░░░░░░░░░    //
//     ░░░▓░▐▓░░░░░░▓▓▓▒░░░░▒░  ▄▄▄▄░░░░▄▓▓█ ░▄▄▄▄  ░▒░░░░░░░░░░░░░    //
//     ░░░▓▌░▓█░░░░░▓▓▓▌░░░░▓▒▓▓▒▒▒▒▒▒▒▓▓▓▓▒▓▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░    //
//     ░░░▐▓░░▓▒░░░░▐▓▓▓░░░▒▒▒███████▓▓▓▓█░▓████████▒░░░░░░▄▓░░░░░▄    //
//     ░░░░▓█░▓▓▒░░░▐▓▓▓▒░░▐▒░░  ▀▀▐▓▓▓▓▌           ░▐░░▄▓▓▒░░░░▄▓▓    //
//     ░░░░░▓█░▓▓█░░░▓▓▓█░░░▓░   ▄▓▓▓▓▓▀            ▄▓▓▓▓░░░░░▄▓▓▀░    //
//     ▄▒░░░▐▓█▓▓▓█▒▓▓▓▓▓█░░▓▓▒▄▓▓▓▓▓▀▒▄▒▒▄▄     ▄▓▓█▓▒░░░░░▓█▓▒░░░    //
//     ▀█▓▓██▓▓▓▓▓▓▓▓▓▓▓███▓▓▓▓▓▓▓█▀   ▀▀▀▀▒▄▄▓█▓▓▓▓▒░░░░▄█▓▓▒░░░░░    //
//     ░░░░▀▀▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓▒░░  ▄▓▓▓▓▓▓▓█▀░░▒▒▒░▒▓██▓▒░░░░░░░    //
//     ▓▓██▓▄▒░▓▓▓▓▓▓▓▓▓▓█▓█▓▓▓▓▓▓▒▒▓▓▒▒▓▓▓▓██▒░▒▒▒▓▓▓▓█▀░░░░░░░░░░    //
//     ░░░▀▓▓▓▓█▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓█▓▓▓▒▓▓█▓▀▀███▓▓▓▓▓█▀░░░░░░░░░░░░░░    //
//     ░░░░░░░▀▓▓▓▓▓▓█▓▓▓▓██▓▓▓▓▓▓▓▓▓▓▓██▒▒░▄▓▓▓▓▓░░░░░░░░░░░░░░░░░    //
//     ░░░░░░░░░▒▒▓▓▓▓▓████▓▓▓▓█▓▓▒▓▓▓▓▒▒▒▓▓▓▓▒▒▓▒░░░░░░░░░░░░░░░░░    //
//     ░▄███████▓███████▓▓▓▓▓▓█▒▒▓▓▓▓▒▒▓▓▓▓▓▓▓▓██▒░░░░░░░░░░░░░░░░░    //
//     █████████████▓▓▓▓▓▓▓▓▓▓▓▓█▀▒▓▓▓▓▓▓████████▒░░░░░░░░░░░░░░░░░    //
//     █████▓██▓█▓▓▓▓▓▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████████████▓▀▀▀░░░░░░░░░░░    //
//     ██████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████▀▀▀▀▒░░░░░░░░░░░░░░░░░░░░░░    //
//     ██▓██▀▀▀▀▀▀▀▀▓▓▓▓▀▀▀▀▀▒▒░░░▄▄▐▄▒░░░░░░░░░░░░░░░░░▄▄░░░░░░░░░    //
//     █▓▀░░░░░░░░▄▄▄▒▀▒▄▄▄░▄▄░▄▄░█▌▐▄▒▄▄▄▄▒▄▄░▐▄▄▄▄▄▄▄░▄▒▄▄░▄▄░░░░    //
//     ▒░░░░░░░░░░███▄▐█▒░█▌██░██░█▌▐█▒██░██░█▌▐█▒▓█▒██░█▌░███░░░░░    //
//     ░░░░░░░░░░░▀██▀░▀██▀░▐██▀█░█▌▐█▒██░█▌░█▌▐█▒▀█▒▀█░█▌██░▀█░░░░    //
//                                                                     //
//                                                                     //
//                                                                     //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract SLMX is ERC721Creator {
    constructor() ERC721Creator("SOULIMMIX", "SLMX") {}
}