// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Metavercians
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    ░░░░░░░░░░░░░░░░░░░░░░░░▒▓▒▒▒░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░▒▓██▓▓▒▒▓█▓▒░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░▒▓█▓▓▒▒▒▒▒▒▒▒▒▓▓▓▒░▒▓░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░▓██▓▒▒▒░░░░░▒▒▒░░░▒▓████▓▒░░░░░░░░░    //
//    ░░░░░░░░░░░░░░▓█▓▒▒▒▒░░░░░░▒▒▒░░░░░▒▒████▓▒░░░░░░░    //
//    ░░░█▓▒░░░░░░░▒▓▒▒▒░░▒░░░░░░░▒▒░░░░░░░▒█▓████▒░░░░░    //
//    ░░▓████▓▒░░░▒█▒▒▒▒░░░░░░░░░░▒▒░░░░░░░▒▒▓█▓▓███░░░░    //
//    ░░▓████████▓█▓▒▒▒▒▒▒▒░░░░░░░▒▒░░░░░░░░▒▓▓▓█████░░░    //
//    ░░██████████▓▓▒▒▒░▒▒▒░░░░░░░▒▒▒░░░░░▒▒▓▒█▓█████▒░░    //
//    ░░███████████▓▒▒▒▒▒▒▒▒▒▒▒▒░░▒▒▒░░▒▓█▓▒▒▒▓██████░░░    //
//    ░▒█████████████▓▒▒▒▓██▓▓▓▓▓▒▒▒▒▒░░░▒▒▒░▒███████░░░    //
//    ░░█████████████▓▒▒▒▒▒▓▓▓▒▒░░▒▒▒▒▒░░░░░▒▒██████▒░░░    //
//    ░░▓█████████████▒▒▒▓▓▒▒▒▒▒░░▒▒▒▒▒▒░░░▒▒▒████▓░░░░░    //
//    ░░░█████████████▓▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▒▒▒▒▓██▒░░░░░░░    //
//    ░░░▒█████████████▓▒▒▒▒▒▒▒▒░▒▓▒▒▒▒▒▒▒▒░▒█▓░░░░░░░░░    //
//    ░░░░░▒▓████████▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█▒░░░░░░░░░    //
//    ░░░░░░░▒▓████▓░░▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█░░░░░░░░░░    //
//    ░░░░░░░░░░▒▒▒░░░░▓▓▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▒▒▒▒▒▓░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▓▒▒▒▒▒▒▒░░░░░░░░░░░░░░░    //
//                                                          //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract METAS is ERC721Creator {
    constructor() ERC721Creator("Metavercians", "METAS") {}
}