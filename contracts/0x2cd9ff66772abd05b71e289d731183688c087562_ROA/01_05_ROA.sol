// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sordida Manus
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▓▓▓███▓▓▓▓▓▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓█▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░▒███▓░░░░░░░░░░░░░░░░░█████▒░░░░░░░░▓▒░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░▒█████░░░░▒▓▓███░░░░░░▒███████░░░░░░░░▒██▒░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░███████▓▓██████▓░░░░░░▒███████░░░░░░░░▒████▓░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░▒███████████████▒░░░░░░▒█████▓▒░░░░░░░▒████████▒░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░▒███████████████░░░░░░░▒███▓▒░░░░░░▒▓████████████▒░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░▒███████████████░░░░░░░▒██▒░░░░░░░█████████████████░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░██████████████▓░░░░░░░░███░░░░░░░░▒█████████████████░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░▓█████████████▓░░░░░░░░█████▒░░░░░░░░▒███████████████▒░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░█████████████▓░░░░░░░░▒███████░░░░░░░░░▒▓███▓▓███████▓░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░▒█████████████▓░░░░░░░▒█▓▒░░░░▒▓▒░░░░░░░░░░░░░░▓███████░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░▒███████████████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░▒████████░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░▒█████████████████▒░░░░░░░░░░░░░░░░░░░░░░░░░▒██████████░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░██████████████▓▒░░░░░░░░░░▒▓███████▒░░░░░░░░█████████▓░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░▓███████████▓░░░░░░░░░░▒▓██████████▒░░░░░░░░█████████▒░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░█████████▓░░░░░░░░░▒▓████████████░░░░░░░░░▒█████████░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░▒██████▓░░░░░░░░░▓████████████▓░░░░░░░░░░▓█████████░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░▓████▒░░░░░░░░▓████████████▒░░░░░░░░░░▒██████████▒░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░▒██▒░░░░░░░▓███████████▓░░░░░░░░░░░▒███████████▒░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░▒▓░░░░░░░▓████████▓▒░░░░░░░░░░░▒▓████████████░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓▓▒▒░░░░░░░░░░░░▒▓█████████████▒░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓███████████████▒░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▓█████████████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▓█████████████████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▓▓████████████▓▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract ROA is ERC721Creator {
    constructor() ERC721Creator("Sordida Manus", "ROA") {}
}