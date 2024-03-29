// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: danoramas Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    ░░░░░░░░░░░░░▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▒▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▓▓▓▓▓▓▓▓▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▒▓█▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▓▒▒▒▓█▓▓▓▓▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▓██▓█▓▓▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░▒▓▓▓▓▓▓██▓█▓▓▒▓▒▓██▓▓▓█▓▓▓██▓▓▓▓▓▓▒▒▓█▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▒▓▓▓▓▓▓▓▓▓░░░░▒▒░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░▓▓▓▓▓▓█▓████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░▒▒▓▓█████▓▓▓▓▓▓█▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░▒▒▒▒▓▓█████▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▓▒▒███▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░▒▒▒▓▓▓▓▓▓▓▒▓█▓█▓▓▓▓▓▓▓███▓▓▒▒▒▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒    //
//    ░░▒▒▒▒▒▓▓▓▓▒▒▓████▓▓█▓▓▒▒▒███▓█▓▓▒▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▒▒▓▓▓▓▓▒▓▓▓▓▓▓▓▓▒▒▓▒▒▓▓▓▓▓▒▒▓▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▓    //
//    ░░▒▒▒▒▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓█▓▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▒▒▓▒▓▒▒▒▒▓▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▒    //
//    ░▒▒▒▒▒▓▓▓▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▒▓▓▒▓▓▓▓█▓▓██▓▓▓▓▓▓▓█▓▓▓▒▓▓▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒    //
//    ░▒▒▒▒▓▓▓▓▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓███▓▓▓▓▓▓▓▒▒▒▓▓▒▒▓▓▓▓▓▒▒▓▓▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░░░░░    //
//    ░░▒▒▓▓▓▒░░░░░▒▒░▒▒▓▓▓█▓▓▓▓▓▓█▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓█▓▓▓▓▓▓▓▓▓░░▒▓▓▓▒▒▒▓▓▓▓▒▒▒▒▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▓▒▓▓▓▒    //
//    ░░░░▒▓░░░░░░░░▓▓▓▒░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▒░▒▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▓▓▓▓░    //
//    ░░░░▒░░░░░░░░░░▓▓▒▒▓▒▒▒▓▓▓▓▓▓██▓▓███▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓██▓▓▓▓▓▓▓█▓▓▓▓▓▓▓▒▓▓▓▓▓▓▒▒▓▓▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▒░░░    //
//    ░░░░░░░░░░░░▒░░▓▓▓▒▒▒▒▒░░▓▓▒▒███▓▓▓███▓▓▓▓▓▓▓▓▓▓▒▓▓▓▓▓▓▒▒▒▓▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▒▓▓▓▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▓▒░░░░░▒▓▓▓▓    //
//    ░░░░░░░░░░░▒▒▒▓▓▓▓▓▓▓▒▒░░▒▓▒▒███▒▒▒▓████▓▓▓▓▓▓▓▓▒▒▓▓▒▒▒▒▓▓▒▒▒▒▒▒▓▓▒▓█▓▓▓▓▓▓▓▓▓▓▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░▒▒░▒▒░░░▓▓█▓▓▒    //
//    ░░░░░░░░░░░▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███▓▓▓▓▓███▒▓██▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒░▒▒░░▓▓▓▓▓▓▓▓▓▓▓▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░▒░░▓▓▓▓▓▓▓▓░▒    //
//    ░░░░░░░░░░░░░▒▒▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▓▓███████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▒▒▒▓▓▒░▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒░▒░░░░░░░░░░░░░░░░░░░░▒▒▓▒▒▓▒▓▓▒▓▓█▓▓    //
//    ░░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓▒▒▓████▓▓▓▓▓▓█▓▓█▓▓▓▓▓▓▓▒▒▒▓▓▒░▒░░▒▓░░░░░▒▒▓▓▓▓▒░░░░░░░░░░░░░░░▒▒░░░▒█▒▓▓▒░░░▒▒▓████    //
//    ░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓██▓▓▓▓▓▓▓▓▓▒░▒▒▒▓▓▒░░░░░░▒▒▒░░░░░░░░░░░░░░░░░░░▒▒▒▒░░▒▓░░░░░░▒▓▓█▓    //
//    ░░░░░░░░░░▒▒▒▓▓▓▓▓▓▓▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▓▓▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒░░▒░░░░▒▒▒░▒▒░▓    //
//    ░░░░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▒▒▓░░▒▓▓▓███▓▓█    //
//    ░░░░░░░░░░░░░░░░▒▓▓▓▓▓▓▓██▓▒▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓█▓▓▓▒▓▓▓▓▓▓▓▒▓▓▓▓▒▓▓▓▓▒▒▓▒░░░░░░░░░░░░░░░░░░░▓▒░░░░░░░▒▒▓░▒▓▒░▒▒▓█▒▒    //
//    ░░░░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▒▓███▓▓██▓▓▓▓▓▓▓▓██▓▓▓▓▓▓▓██▓▓█▓▓▓▓▓▓█▓▓▓▓▓▓▒▒▒▒▒▓▓▒▓▒▒▒░░░░░░░░░░░░░░░░▒▓▒▒▒▒░░░░░▒█▒░▒░░░▒▓█▒░    //
//    ░░░░░░░░░░░░▒▒▓▓▓▓▓▓▓▓▒▒▒▒▒▒█▓▓▓▓▓▓▓▓▓▓▓▓██▓▓████▓▓▒▒▓▓▓▓▓██▓▓▓▒▓▒▒░░░░▒▒▒▒▒▒░▒░░░░░░░░░░░░░░░░▒▓▓██▒▒▒▒░░░▒▓█░░░░▒▒▒░██    //
//    ░░░░░░░░░░░░▒▓▓▓▓▓▓▓▒░░░▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓███▓▓▓███▒▒▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒░░▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░▒▒▒████▓▓▓▓▓███▓░░▒▒▓▒▓██    //
//    ░░░░░░░░░░░░░▒▒▒▒▒░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███▓▒▒████▓▓▓▓▓▓▓▓▒▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░▒▓██████▒▓▓▓█▓▓██▓█▓█▓▓██    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▒░▓▓▓▓███▒░▓███▓▒░▒▒░▓▓░░░░▒▒▓▒▓▓▓▓▓▓▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░▒▓█▓██▓▓▓▓▓▓▓█▓███▓▓▓█▓░▓    //
//    ░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▒▓█▒░░▓████▓░▓███▓░░▒▓▓▓▓▓▓▒░▒░░▒▒▓▓▒▒▓▓▒▒▓▒▒▒░░░░░░░░░░░░░░░▒▒▓▒▓▓▒▒▒▓▓█▓▒▓▒▒▓▓█▒░▓█▓▒▓    //
//    ░░░░░░░░░░░░░░░░░░░░░░░▒▒▓▒▒▒▒▒▒▒▓██░░▓████▓▒██▓▓░░▒▓█▓▓▓▓▓▓▓▓▓▓▒▒▒▒▓▓▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░▒▒░░░░░░░░▒▓▓███▒▒▓█▒▓███▓▓    //
//    ▓▒▒▒░░░░░░░░░░░░░░░░░░▒░░▒▒▒░░░░░░▓▓▓░▓█████▓███▓▓▓▒▒░░░▒▒▒░░▒▒▒▒▒▓▒▓▓▓▓▓▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░▒▓▒▓▒▒░░░█▓▓█▒▒█▓▓▓░    //
//    ▒▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▒▓███████▓░░░░░░░░░░░░░░▒▒▒▒▒▒▒▓▒▒▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▓▒▓▓░░▓▓▓██▓▓█▓░░▒    //
//    ▓█▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▓███████░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▒█▓▒▒░▒▒░███▓░░░░    //
//    ███▓▓▒▒▒░░░░░░░░▒▓▓▓▒░░░░░░░░░░░░░░░▒▓███████▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▓▓▓▒▒▒▒░▒██░░░░▒    //
//    ███████▓▓▒░░▒▒▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░▓██▓████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▓▓▒▒░░░░▒▓▒░░░░░░░░▓█░░░░░    //
//    ███████████▓▓▓▓█▓█▓▓▓▓▓▓░░░░░░░░░░░░░▓██████▓░░░░░░░░░░░░▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░▓████▓██▓▓▓▒░░░░░░░░░█▓░░░░    //
//    █████████████████▓▓▓▓▓▓▓▒░░░░░░░▒▒▒▒▒▓▓█████░░░░░░░░░░░░▓██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒██▓██▓▓██▓░░▓▒▒▒░▒▒▒░▓█▒░░    //
//    ██████████▓███▓▓▓▓▓▓▓▓▓▓█▓▓▒░▒▒▒▓██▓▓███████░░░░░░░░░░▒███▒░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█▓▓▒▓▓▒▓▒░▒▓▓▓█▓▓▒██████░░    //
//    ███████▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓███▓▓█▓▒▒▓▓████████▓░░░░░░░░░███████▒▒▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▒▓▓▒▒▒▒▒▒▒▒▒▒░░░▒▒▓▓█▓▓█▓    //
//    ███████▓▓▓█▓██▓█████▓▓▓█████████████████████░░░░░░░░░▓██████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▓▒▒▓▒▓▒▒░░░░░░░▒▒▒▒░░░▒▓▓██    //
//    ████▓█████▓▓▓█████▓▓▓▓███████████████████████▒▒░░░░░░░▒████▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒░░░░░░░▒▒▓▓▓▓▓▒▒▒▓▓▒▒▓▓▓▓█    //
//    ████▓████▓▓▓▓▓████████████████████████████████▓▓▒░░░░░░▓███▒░░▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█    //
//    █████████████▓██████████████████████████████████▓▓▒▓▓░░░███░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓█▓▓▓▓    //
//    ██████▓███████████████▓▓████████████████████████████▓▒▒░██▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████████    //
//    ███▓█████████████▓█▓▓██▓▓▓▓███████████████████████████████▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████████    //
//    █████████████▓██▓▓▓▓▓███▓▓▓▓▓██████████████████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███▓▓█▓█████████    //
//    ███████▓████████▓▓▓▓▓█████▓▓▓▓▓███████████████████████████████▓▓▓▓▒░░░░░░░░░░░░░▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓█▓▓▓███████▓██▓█████████    //
//    █████▓█████████████████▓▓▓█▓▓▓▓▓████████████████████████████████████▓▓▒▒░░░▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████████████▓███▓███    //
//    █████▓▓▓█████████████████▓▓▓▓▓▓▓█████████████████████████████████████████▓▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████████▓▓▓▓▓███████    //
//    █████▓█████████████████████▓▓▓▓███████████████████████████████████████████▓▒▒▒▒▒▒▒▒▓▓▓▓▓▓██████████████████▓▓▓▓▓████████    //
//    ███████▓▓▓█████████████████████████████████████████████████████████████████▓▓▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓█████████████▓████████████    //
//    ██████████████████████████████████████████████████████████████████████████▓██▓▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓████████▓▓▓▓█▓▓▓▓███████    //
//    ██████████▓▓▓████████████████████████████████████████████████████████████▓▓▓██▓▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓█▓▓▓▓▓▓▓▓▓█▓██████    //
//    ██████▓▓███▓▓▓██▓█▓▓▓██████████████████████████████████████████████████▓███████▓▓▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓█▓▓██▓█████████████    //
//    ████████▓▓███▓▓▓▓▓▓█████████▓███████████████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓█████▓▓█████████    //
//    ███████████████▓▓█▓████████▓▓█████████████████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓██▓▓▓▓▓▓▓▓▓▓████    //
//    ███████████▓████▓█████▓███▓▓▓▓▓█████████████████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███▓▓███    //
//    ██████████████▓▓████▓████▓▓▓▓█████████████████████████████████████████▓▓▓▓▓▓████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓███████    //
//    █████████████████████▓▓▓██▓███████████████████████████████████████████▓▓▓▓▓▓▓▓████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓████▓▓██████    //
//    █████████████████▓▓███▓█████████████████████████████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▓██▓████████    //
//    ████████████████████████████████████▓▓██████████████████████████████████████████████████████▓██▓▓▓▓▓▓▓▓▓████████████████    //
//    ███████████████████████████████████████▓███████████████████████████████████████████████████████████▓▓▓██████████████████    //
//    ████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████    //
//    ▓███████▓███████████████████████████████████████████████████████████████████████████████████████████████████████████████    //
//    █▓██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████    //
//    ████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████    //
//    ████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████    //
//    ████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████    //
//    █████████████████████████████▓▓█████████████████▓███████████████████████████████████████████████████████████████████████    //
//    ████████████████████████████▓▓▓▓▓███████████▓▓█▓▓▓▓▓▓▓▓▓████████████████████████████████████████████████████████████████    //
//    ████████████████████████████▓▓▓▓▓██████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████████████████████████████████████████████████████    //
//    █████████████████████████████▓▓▓▓▓████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████████████████████████████████████████    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AMBROSI is ERC1155Creator {
    constructor() ERC1155Creator("danoramas Editions", "AMBROSI") {}
}