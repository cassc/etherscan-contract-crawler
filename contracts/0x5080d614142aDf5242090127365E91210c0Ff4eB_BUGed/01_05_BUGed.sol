// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Summer Wagner Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                   //
//                                                                                                   //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░░░░░░░░░░▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░     //
//    ░░░░░▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█▓░░░░░░░░░░░█▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▒░░░░     //
//    ░░░░░▒▓▓▓▓▓▒░▒░░░░░░░░░░░░░░░░░░░░░░░░▒▒░░░░░░░░░░░█░░░░░░░░░░░░░░░░░░░░░░░░▒▒░▓▓▓▓▓▓░░░░░     //
//    ░░░░░░░░░░▒▓▓▓▒▒░░░░░░░░░░░░░░░░░░░░░░▒█▓▓███████▓▓▓▒░░░░░░░░░░░░░░░░░░░░░▒▒▓▓▓▓░░░░░░░░░░     //
//    ░░░░░░░░░░░▒▓▓█▓▒▒▒░░░░░░░░░░░░░░░░▒▓████▓▓▓▓▓▓▓▓▓████▓▒░░░░░░░░░░░░░░░░▒▒▓▓█▓▓▒░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░░▒▓▓▒▒▒░░░░░░░░░░░░░▓███▓▓▓▓▒▒▒▒▒▒▒▓▓▓▓██▓▓░░░░░░░░░░░░░▒▓▓▓▒░░░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░░░░░▒▓▒▒░░░░░░░░░░░█▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓█▓░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░░░░░░░▓▒▓▒░░░░░░░░░█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓░░░░░░░░░▒▓▓▒░░░░░░░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░░░░░░░░▒▓▓▒▒░▒▒▓▓██▓▓▓▒▒▒▒▒▒▓▓▓▓▓▓▓▓▒▒▒▒▒▓▓▓█▓▓▒▒░░▒▒▓▓▒░░░░░░░░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░░░░░░░░░█▓▓▓█████▓▓▓▓▒▒▒SUMMER WAGNER▒▒▒▒▒▓▓▓▓████▓▓▓▓▒░░░░░░░░░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░░░░░░░░░▒▒▒██████▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓█████▒▒░░░░░░░░░░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░░░░░░░░░░░▒██████▓▓▓▓▒▒BUG IN DREAMLAND▒▒▓▓▓▓▓▓▓█████░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░▒███████▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓██████░░░░░░░░░░░░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████▓░░░░░░░░░░░░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░░░░▒▒▒░░░░░░▓███████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███████▒░░░░░░▒▒░░░░░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░░░▒█▓▓▓▓▒▒▓▓▓▓███████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████▓▓▓▓▒▒▒▓▓▓█▓░░░░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░░▒█▒░░▒▓▓▓▓▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓█▓▓▓▓▓▓██▓▓▓▓▓▓▒▒▒▒▒▒▒▒▓▓▓▓▓▓░░░▓▓░░░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░▒▓█▒░░▒▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓░░░▓█▓▒░░░░░░░░░░░░     //
//    ░░░░░░░░░▒▒▓▓█▒░░░▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓░░░░▓█▓▒▒░░░░░░░░░     //
//    ░░░░░▒▒▒▓▓▒▓░░░░░▒▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓░░░░░▒▓▓▓▒▒▒░░░░░     //
//    ░░░░▓█▒░░░░░░░░░░▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░█▓▒░░░     //
//    ░░░░░▒░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░▒░░░░     //
//    ░░░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█▓▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▓█▓▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░░░░▒▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░░░░▓▓▓█████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░▒▓▓███▓██████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓██▓▓▓░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░▒██░░▒▓███████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓░░▓██▒░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░░██░░░▓▓███████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████▓▒░░▓█▓░░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░░▓█▓░░░▓▓████████▓▓▓▓▓▓▓▓▓▓▓▓▓███▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▒░░░██▒░░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░░▓█▓░░░░▓▓████████▓▓▓▓▓▓▓▓▓▓▓▓███▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███▓▓▒░░░▒██░░░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░░▓██░░░░░░▓▓████████▓▓▓▓▓▓▓▓▓▓███▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▒░░░░░▓█▓░░░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░░▓▓▓░░░░░░░▓▓████████▓▓▓▓▓▓▓▓▓███▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░▒█▓▒░░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░▒▓▓▓░░░░░░░░▒▒▓▓██████▓▓▓▓▓▓▓▓███▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░█▓▓░░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░▒▓▒▓▒░░░░░░░░░░░▒▓▓▓█████▓▓▓▓▓▓███▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░▓▓▓▓▒░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░▓█░░░░░░░░░░░░░░░░▒▒▓▓▓▓▓▓▓▓▓▓███▓▓▓▓▓▓▓▓▓▓▒▒░░░░░░░░░░░░░░░▒█▒░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░▒▓█▒░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░▓█▓░░░░░░░░░░░░     //
//    ░░░░░░░░░░░▓██▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓█▓░░░░░░░░░░░     //
//    ░░░░░░░░░░░░▓█▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓█▒░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░     //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░     //
//                                                                                                   //
//                                                                                                   //
//                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////


contract BUGed is ERC1155Creator {
    constructor() ERC1155Creator("Summer Wagner Editions", "BUGed") {}
}