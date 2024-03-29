// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FRESH START
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    ▓█▓▓▓▓▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▓▓▓▓█    //
//    ▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒█    //
//    ▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓    //
//    ▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓    //
//    ▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒    //
//    ▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░▒    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▓▒░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▓▓█▓▓▓░░▓▓▓▓▓▓▓▓▒▓▓▒█▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▓▓█▓█▓▓▓▓▓▓▒░░░░▓▓▒▒▓▒▒▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓█▓▒▒░░░░░░░░░▒▓▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓██▓▓█▓▓▓█░░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░▓▓█▓█▓██▓▓▓▓▓▓▓▓░░░░░░░░░░░░░▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░▒▓▓▓▓███▓▓█▓▓▓▓░░░░░░░░░░░░░░░▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░▓▓▓▓▒▓██▓▓▓▒▒▒░░░░░░░░░░░░░░░░░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▓▓▓▓▓▓▒▒▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░▒▓▓▒▓▓▓██▒▓▓▓█▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░▒▓▓▓▒██▓███▓▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░▒▒░░▒▒█▓▓▓██▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░▓░░░░░▓██▒▓█▓▒▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░▒▒░░▒▒▒▒▓██▓▓▒▓█▓▓█▓░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░▒░▒▒▒▒▒▒▒▓▒▒▒▓▓█████▓▒▒░░░░░░░░░░░░░░░░░░░░░░▒▓▓▓▓▒▓▓▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░▒▒▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░▒▒░░░░░░░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░    //
//    ░▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▒▓▓▒▒▒▒▒▓▓▓▓▒▓▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒░░░░▒░░░░░▒▓▓▓░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░░░▒▒░░▒▒░░░░░░▒▒░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▒▒▒▒▒▒░░░▒▒░░▒▒▒▒░▒▒░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒░▒░░░▒▒▒▒▒░░▒░░▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▒▒░░▒░▒░░░▒░░▒▒▒▒▒▓▒░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒░░▒▒▒▒░░▒▒▒▒▒▒▒▓▒░░░░░░░░░░░░░░░░░░░░░░░    //
//    ▓█▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒░▒▒▒▒▒▓▒▒▒▒▒▒▓▒░░░░░░░░▒▒▒▒▒▒▒▒▒░░░░░░▒    //
//    ▓▓▓▓▓████▒░░░░░░░░▒░▓██████████████▒▒▒▒▒▒▒▒▓▒▓███▓▓▓▓▓▒▒░▒▓▒▒▒▒▓▒░░░▒▓███████████▓▒▒▒▒▒▒▒▓    //
//    ▒▒░░░░░▒▒▒▓█████████▓▒▓▓▓▓▓▓▓▓▓█▓▓██▓▓▓▓▓▓▓▓▓▓█▓▓▓▒▒▒▓▒▒░▒▓▒▓▓█▓▓▓▓▓██▓▒▒▒▒▒▒▒▒▒▒▒▒▓██████    //
//    ▓████████▓▓▒▒▓▓▓▓▓██▒▒▒▒▒▒▒▒▒▒▒▓▒▓███████████▒░░▒▒░▒▒▓▒▓▓▒▒▓▓▓████████▓▓▓▓▓▓▓▓▓▓█▓▓▒▒▒▒░▒▒    //
//    ▓▓▒▒▒▒▓▓▓▓▒▒▒▒▒▒░░▒░▓█████████████▒░░░░░▒▒▒▓▒█████▒░░░▒▒▓▒░▒░░░▒▓███▒▓█████████████▓▓▓▓▓▓█    //
//    ▒▒░░░░░░░▒▒▓████████▒▒▒▒▒▒▒▒▓▓▓█▓█▓▓▓▓▓▓▓▓▓▓▓▓██▓▓░░░░░░▒░░░░░░▒███▓▒▓▓▒░░░░░░░░▒▒▓▓▓▓▓▓▓█    //
//    ▒▒░░░░░░░░░░░░▒▒▒▒▒▒░░░░░░░░░▒▒▓▓█████▓▒░░░░░░▓██▓▒░░░░░▒░░░░░▒▒██▓▒░░░░░░░░░░░░░░░░░░░░░▒    //
//    ▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒░░░░░▒▒█▓█▓▓▒░░░▒░░▒▒▒▒▓▓█▓▒░░░░░░░░░░░░░░░░░░░░▒▒    //
//    ▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░░░▒▓█▓█▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓█▒░░░░░░░░░▒░░░░░░░░░░▒▓    //
//    ▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░░░░░░░▒▓▓█▓█▓▓▓▓▓▓█▓▓▓▓▓█████▓░░░░░░░░░░░░░░░░░░░░▒▓    //
//    ▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░▒░░░░░▒▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓█▓░░░░░░░░░░░░░░░░░░░▒▒█    //
//    ▓█▓▓▓▓▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░▒░░░░░░░░▒█▓▓█▓▒░░░░░░░░░░░░▒▓█▓█▓░░░░▒▒░▒▒▒▒▒▒▒▒▒▒▓▓▓▓█    //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract FRSH is ERC721Creator {
    constructor() ERC721Creator("FRESH START", "FRSH") {}
}