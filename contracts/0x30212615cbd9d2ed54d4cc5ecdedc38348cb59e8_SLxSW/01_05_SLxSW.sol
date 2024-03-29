// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Satria Lingga x Sigi Wimala
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    ██████████▓▒▒░░░░░░░░░░░░█████████▓▒▒░░░░░░░░░░░░░▓██████▓▓▒░░░░░░░░░░░░░░░▒█████▓▒▒░░░░░░░░░░░░░░░░▓███▓▒▒░░░░░░░░░░░░░░░░░▒▓▓▓▒▒░░░░░░░░░░░░░░░░░░▒▓▓▓▒▒▒░░▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓█████████▓░░░░▒▒▒▒▓▓▓██████     //
//    █████████████████▓▒░░░░░░░▓██████████████▓▒░░░░░░░░░▓███████████▓▓▒▒░░░░░░░░░░██████████▓▓▒░░░░░░░░░░░░████████▓▓▒▒░░░░░░░░░░░░▒███████▓▒▒░░░░░░░░░░░░░░▓████▓▓▒▒░░░░░░░░░░░░░░▒▒▒▓█▓▒░▒▒▒▓▓▓▓▓█████████    //
//    ██████████████████████▓▒░░░███████████████████▓▓▒░░░░▓████████████████▓▓▒▒░░░░░▓███████████████▓▒▒░░░░░░▒█████████████▓▓▒▒░░░░░░░▒████████████▓▒▒░░░░░░░░░▒██████████▓▓▓███████████▒░░░░░░░░░░░░░░░░░░░▒    //
//    ▓█▓▒▒░░░░░░░░░░░░░░░░░░░▒▒░▒█▓▓▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▒▒░▓█▓▓▓█████████████████▓▓▒▒▓████████████████████▓▓▒░░▓██████████████████▓▓▒░░░░▓████████████████▓▓▒░░░░▒▓███████████████████▓░░░░░░░░░░░░░░░░▒▒▒▓▓▓    //
//    ▒██████▓▓▒░░░░░░░░░░░░░░░░░░█████▓▒▒░░░░░░░░░░░░░░░░░░░▓██▓▒▒░░░░░░░░░░░░░░░░░░░░░█▓▓▒▒░░░░░░░░░░░░░░▒▒▒▒▒░▒▓█▓▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▒▒▒▓█▓▓▓▓█▓▓████████████▓▓▒▒▓████████████████▒░░░░░▒▒▒▓▓▓████████████    //
//    ▒███████████▓▓▒░░░░░░░░░░░░░▒█████████▓▓▒░░░░░░░░░░░░░░░▓███████▓▒▒░░░░░░░░░░░░░░░░▓█████▓▓▒░░░░░░░░░░░░░░░░░▒████▓▓▒░░░░░░░░░░░░░░░░░░░▓██▓▒▒░░░░░░░░░░░░░░░░░░░▒▓▓▓▒▒░░▒▒▓▓█▓░▒▒▓▓████████████████████    //
//    ░████████████████▓▓▒░░░░░░░░░▓██████████████▓▒░░░░░░░░░░░█████████████▓▒▒░░░░░░░░░░░▒██████████▓▓▒░░░░░░░░░░░░░▒█████████▓▒▒░░░░░░░░░░░░░░▓██████▓▓▒▒░░░░░░░░░░░░░░░▓███████▓░░░░░░░░░░░░░░░░▒▒▒▒▓▓▓▓▓██    //
//    ░██████████████████████▓▒░░░░░███████████████████▓▒▒░░░░░░██████████████████▓▒░░░░░░░░███████████████▓▓▒░░░░░░░░░▓█████████████▓▓▒░░░░░░░░░░▓███████████▓▓▒░░░░░░░░░░░▒████▒░░░░░░░░░░░░░░░░░░░░░▒▒▒▓▓▓█    //
//    ▒▓█▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▓▓▓▓▓▓█▓▒▒▓████████████████████████▓▒░░██████████████████████▓▓▒░░░▓████████████████████▓▒▒░░░░██████████████████▓▓▒▒░░░░░▓████████████████▓▓▒░░░░░░░▓░░░░░░░░░░░░▒▒▒▓▓▓████████████    //
//    ░▒███▓▓▒░░░░░░░░░░░░░░░░░░░░░░░██▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▒▒░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███▓▓▒▒▒███████████████████████▓▒▒▒▓█████████████████████▓▒▒░░░▒▒▓▓▓██████████████████████░    //
//    ░░████████▓▓▒░░░░░░░░░░░░░░░░░░▒██████▓▒▒░░░░░░░░░░░░░░░░░░░░█████▓▒░░░░░░░░░░░░░░░░░░░░░░██▓▓▒▒░░░░░░░░░░░░░░░░░░░░░░▒█▓▒▒░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓██████████████████████░░    //
//    ░░█████████████▓▒▒░░░░░░░░░░░░░░▓██████████▓▓▒░░░░░░░░░░░░░░░░█████████▓▓▒░░░░░░░░░░░░░░░░░▓███████▓▒▒░░░░░░░░░░░░░░░░░░▓█████▓▓▒░░░░░░░░░░░░░░░░░░░▒████▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▓▓▓▓████▓░▒▒    //
//    ░░██████████████████▓▒░░░░░░░░░░░████████████████▓▒░░░░░░░░░░░░██████████████▓▒▒░░░░░░░░░░░░▒████████████▓▒░░░░░░░░░░░░░░▒██████████▓▓▒░░░░░░░░░░░░░░░▒████████▓▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▓▓▓██▒░░░░    //
//    ░░▓██████████████████████▓▒░░░░░░▓████████████████████▓▒░░░░░░░░██████████████████▓▓▒░░░░░░░░░█████████████████▓▒▒░░░░░░░░░▒██████████████▓▓▒▒░░░░░░░░░░▒█████████████▓▒▒░░░░░░░░░▒▒▓▓▓███████████░░░░░░    //
//    ▓▒▒██████████████████████████▓▓▒░░█████████████████████████▓▒▒░░░███████████████████████▓▒▒░░░░▒█████████████████████▓▒▒░░░░░▓███████████████████▓▒▒░░░░░░▒█████████████████▓████████████████████░░░░░░░    //
//    ░░░█▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░▒░▒█▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▒▒▒██▓▓▓▓▓▓▓▓▓▓▓██▓▓▓█████████▓▒▒▒█████████████████████████▓▓▒░▒████████████████████████▓▒▒░░▒██████████████████████████████████▓░░░░░░░░    //
//    ░░░██████▓▒░░░░░░░░░░░░░░░░░░░░░░░░▓████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░██▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░▒░▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▒▒▒██▓▓▓▓▓▓▓▓▓▓▓▓█████████████████▒░░░░░░░▒▒    //
//    ░░░▓█████████▓▓▒░░░░░░░░░░░░░░░░░░░░████████▓▒▒░░░░░░░░░░░░░░░░░░░░░███████▓▒░░░░░░░░░░░░░░░░░░░░░░▒█████▓▒░░░░░░░░░░░░░░░░░░░░░░░▓███▓▓▒░░░░░░░░░░░░░░░░░░░░░░░▒██▓▓▒░░░░░░░░░░░░░░░░▒▒▒▒▓██▒▒▒▓███████    //
//    ░░░▓██████████████▓▒░░░░░░░░░░░░░░░░▓████████████▓▒▒░░░░░░░░░░░░░░░░░███████████▓▒░░░░░░░░░░░░░░░░░░▒█████████▓▓▒░░░░░░░░░░░░░░░░░░░▓███████▓▓▒░░░░░░░░░░░░░░░░░░░▒██████▓▓▒░░░░░░░▒▒▓▓▓████░░░░░░░░░░▒▒    //
//    ░░░▒███████████████████▓▒░░░░░░░░░░░░█████████████████▓▒░░░░░░░░░░░░░░███████████████▓▓▒░░░░░░░░░░░░░░██████████████▓▒▒░░░░░░░░░░░░░░▒████████████▓▒▒░░░░░░░░░░░░░░░░▓█████████████████████░░░░░░░░░░░░░    //
//    ░░░░███████████████████████▓▒▒░░░░░░░▒███████████████████▓█▓▒░░░░░░░░░░███████████████████▓▓▒░░░░░░░░░░▓█████████████████▓▓▒░░░░░░░░░░░▒████████████████▓▒▒░░░░░░░░░░░░▓█████████████████▓░░░░░░░░░░░░░░    //
//    ▒░░░████████████████████████████▓▒░░░░██████████████████████████▓▒░░░░░▒████████████████████████▓▒░░░░░░▒██████████████████████▓▒▒░░░░░░░▓████████████████████▓▒░░░░░░░░░▓██████████████▒░░░░░░░░░░░░░░░    //
//    ▓▓▒░▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████████▓▓▒▒██████████████████████████████▓▒░▒████████████████████████████▓▒▒░░▓█████████████████████████▓▓▒░░░░████████████████████████▓▓▒░░░░░▓███████████▒░░░░░░░░░░░░▒▒▓▓    //
//    ░░░░▒██▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓█▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒█▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒░▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███████▓▒▒▓████████████████████████████▓▓▒▒▓████████░░░░░▒▒▓▓▓████████    //
//    ░░░░▒███████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░█████▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░▒███▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░▒██▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▒▓▓▓░▒▒▓███████████████    //
//    ░░░░░███████████▓▒░░░░░░░░░░░░░░░░░░░░░░▒█████████▓▒░░░░░░░░░░░░░░░░░░░░░░░▒████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░▓██████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░▓████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░▓█▓░░░░░░░░░░░░░▒▒▒▓▓▓▓    //
//    ░░░░░███████████████▓▒░░░░░░░░░░░░░░░░░░░█████████████▓▒░░░░░░░░░░░░░░░░░░░░▒████████████▓▒░░░░░░░░░░░░░░░░░░░░▒██████████▓▒▒░░░░░░░░░░░░░░░░░░░░▒█████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░▓██████████████████▓▒▒░░░░░░░░░░░░░░▒█████████████████▒▒░░░░░░░░░░░░░░░░▓███████████████▓▓▒░░░░░░░░░░░░░░░░░██████████████▓▒▒░░░░░░░░░░░░░░░░░▓████████████▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░▓██████████████████████▓▒░░░░░░░░░░░░▓████████████████████▓▒▒░░░░░░░░░░░░▓███████████████████▓▓▒░░░░░░░░░░░░░▓█████████████████▓▓▒░░░░░░░░░░░░░░▓████████████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░▒███████████████████████████▓▒░░░░░░░░█████████████████████████▓▒░░░░░░░░░▓███████████████████████▓▓▒░░░░░░░░░▒██████████████████████▓▒░░░░░░░░░░▒████████████████████▓▓▒░░░░░░░░░░░░░░░░░░▒▒▓▓████    //
//    ▓▒░░░░███████████████████████████████▓▒░░░░▓████████████████████████████▓▓▒░░░░░▓███████████████████████████▓▒▒░░░░░░██████████████████████████▓▒░░░░░░░▒████████████████████████▓▒▒░░░░▒▒▓▓████████████    //
//    ▓▓▓▓▒░███████████████████████████████████▓▒░█████████████████████████████████▓▒░░▓███████████████████████████████▓▒░░░▓█████████████████████████████▓▒░░░░▓█████████████████████████████████████████████    //
//    ░░░░░░██▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▒░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▓█▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓█▓▓▓▓████████████████████████████▓▒▒████████████████████████████████████████████    //
//    ░░░░░░▓█████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░████▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓██▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▒░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▓▓▓███████████    //
//    ░░░░░░▒█████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░▒████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓██████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓████▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓    //
//    ░░░░░░░█████████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░▓███████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░▓█████████▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░▓████████▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░▓███████▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░█████████████████▓▒░░░░░░░░░░░░░░░░░░░░░███████████████▓▒░░░░░░░░░░░░░░░░░░░░░░▓█████████████▓▒░░░░░░░░░░░░░░░░░░░░░░▒████████████▓▓▒░░░░░░░░░░░░░░░░░░░░░░▒███████████▓▒░░░░░░░░░░░░░░░░░░░░░░▒▓    //
//    ░░░░░░░▓███████████████████▓▒░░░░░░░░░░░░░░░░░░▓██████████████████▓▒░░░░░░░░░░░░░░░░░░░██████████████████▓▒░░░░░░░░░░░░░░░░░░░████████████████▓▒▒░░░░░░░░░░░░░░░░░░░▒██████████████▓▒▒░░░░░░░░░▒▓▓██████    //
//    ░░░░░░░▒███████████████████████▓▒░░░░░░░░░░░░░░░███████████████████████▓▒░░░░░░░░░░░░░░░█████████████████████▓▒░░░░░░░░░░░░░░░░▒███████████████████▓▒▒░░░░░░░░░░░░░░░░▓█████████████████▓▓▓█████████████    //
//    ░░░░░░░▒███████████████████████████▓▒░░░░░░░░░░░▒██████████████████████████▓▒░░░░░░░░░░░░█████████████████████████▓▒░░░░░░░░░░░░░███████████████████████▓▒▒░░░░░░░░░░░░░████████████████████████████████    //
//    ░░░░░░░░███████████████████████████████▓▒░░░░░░░░██████████████████████████████▓▒░░░░░░░░░████████████████████████████▓▒▒░░░░░░░░░▓██████████████████████████▓▒░░░░░░░░░░▒██████████████████████████████    //
//    ██▓▒░░░░███████████████████████████████████▓▒░░░░░█████████████████████████████████▓▒░░░░░░████████████████████████████████▓▒░░░░░░▒██████████████████████████████▓▒░░░░░░░▓████████████████████████████    //
//    ██████▒░▓██████████████████████████████████████▓▒░▓█████████████████████████████████████▓▒░░███████████████████████████████████▓▓▒░░░██████████████████████████████████▓▒░░░░▓██████████████████████████    //
//    ░░░░░░░░▒▓▒░░░░░░▒░░░░░░░░░▒░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░█▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████████████████▓▓▒██████████████████████████████████████▓▒▒█████████████████████████    //
//    ░░░░░░░░▒███▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒███▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓██████    //
//    ░░░░░░░░░███████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░███████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░████▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓██▓▒▒░░░░░░░░░░░░░░▒▓    //
//    ░░░░░░░░░██████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓███████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██████▓▒▒░░░▒▒▓█████    //
//    ░░░░░░░░░▓█████████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓████████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░████████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒██████████▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒██████████████████    //
//    ░░░░░░░░░▒█████████████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░████████████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░███████████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░██████████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░▓███████████████░    //
//    ░░░░░░░░░▒████████████████████▓▒░░░░░░░░░░░░░░░░░░░░░░▓███████████████████▓▒░░░░░░░░░░░░░░░░░░░░░░▒██████████████████▓▒░░░░░░░░░░░░░░░░░░░░░░░▓████████████████▓▒▒░░░░░░░░░░░░░░░░░░░░░░░█████████████▒░    //
//    ░░░░░░░░░░████████████████████████▓▒░░░░░░░░░░░░░░░░░░░███████████████████████▓▒░░░░░░░░░░░░░░░░░░░▒█████████████████████▓▒░░░░░░░░░░░░░░░░░░░░▒████████████████████▓▒░░░░░░░░░░░░░░░░░░░░▒██████████▓░░    //
//    ░░░░░░░░░░███████████████████████████▓▒░░░░░░░░░░░░░░░░▒██████████████████████████▓▒░░░░░░░░░░░░░░░░▒█████▒░█████████████████▓▒▒░░░░░░░░░░░░░░░░░███████████████████████▓▒▒░░░░░░░░░░░░░░░░░▓████████░░░    //
//    ░░░░░░░░░░▓██████████████████████████████▓▒░░░░░░░░░░░░░▓█████████████████████████████▓▒░░░░░░░░░░░░░▒██▒▒▓███████████████████████▓▒░░░░░░░░░░░░░░▓██████████████████████████▓▒░░░░░░░░░░░░░░░▓█████░░░░    //
//    ░░░░░░░░░░▓█████████████████████████████████▓▓▒░░░░░░░░░▒█████████████████████████████████▓▒░░░░░░░░░░░░██████████████████████████████▓▒░░░░░░░░░░░▒█████████████████████████████▓▓▒░░░░░░░░░░░▒███▒░░░░    //
//    ██▓▒░░░░░░▒█████████████████████████████████████▓▒░░░░░░░▓████████████████████████████████████▓▒░░░░░░░▒██████████████████████████████████▓▒░░░░░░░░▒█████████████████████████████████▓▒░░░░░░░░░▓▓░░░░░    //
//    █████▓▒░░░░█████████████████████████████████████████▓░░░░░█████████████████████████████████████▓▒░▒▓▓▒░░▓█████████████████████████████████████▓▒░░░░░░▓████████████████████████████████████▓▒░░░░░░░░░░░    //
//    █████████▒░████████████████████████████████████████████▓▒░▒█████████████████████████████████▓▒░░░█▒░▒█▒░░▓█████████████████████████████████████████▓▒░░▒███████████████████████████████████████▓▒░░░░░▒▒    //
//    ░░░░░░░░░░░▓▓▒░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▒▒▒▒▒▒▒▒▓▒▓█▓▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▒▓▓▒▒▓▓▓▓▓███▓▓▓▓▓▓▓▓▓██▓▓█▓███████████████████████████▓▓███████████████████████████████████████████████    //
//    ░░░░░░░░░░░▒███▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██▓▒░░░░░░░░░░░░░░░░░░░░░▒░░░▒░░▒█████▓▒░░░░░░░▓██▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▓    //
//    ░░░░░░░░░░░▒██████▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓█████▓▒░░░░░░░░░░░░░░░░▒▒▒█▒░░░░░██▒░░░░░░▒░░░░▓████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒███▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░█████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░████████▓▒░░░░░░░░░░▒▓██████▓░░░▓██▒░░░░░░░░░▒░░▓███████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██████▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░████████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓███████████▓▒░░░░░░▓█████████▓████████░░░░░░░░░░▓██████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓█████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░▓██████████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██████████████▓▒░░██████████████▓░░░░▒▓▒░░░░░░░░░▓█████████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒████████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░▒██████████████████▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒██████████████████████████████▓░░░░░░░░░░░░░░░░░░▓████████████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░███████████████▓▒░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░█████████████████████▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓███████████████████████████▒░░░░░░░░░░░░░░░░░░░░░▓██████████████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓██████████████████▒▒░░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░████████████████████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░▒██████████████████████████▒░░░░░░░░░░░░░░░░░░░░░░░▓█████████████████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░▒█████████████████████▓▒░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░███████████████████████████▓▒░░░░░░░░░░░░░░░░░░░░░░▓████████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░▓████████████████████████▓▒░░░░░░░░░░░░░░░░░░░░░░▒████████████████████████▓▒░░░░░░░░░    //
//    ░░░░░░░░░░░░░▓█████████████████████████████▓▒░░░░░░░░░░░░░░░░░░░░██████████████████████▒░░░░░░▓▒░░░░░░░░░░░░░░░░░░░░▓███████████████████████████▓▒░░░░░░░░░░░░░░░░░░░░▓██████████████████████████▓▒░░░░░    //
//    ░░░░░░░░░░░░░▒█████████████████████████████████▒░░░░░░░░░░░░░░░░░▒███████▓██████████▓▒░░░░░░▓████▓▓░░░░░░░░░░░░░░░░░░▓██████████████████████████████▓▒░░░░░░░░░░░░░░░░░▒█████████████████████████████▓▒░    //
//    ░░░░░░░░░░░░░▒████████████████████████████████████▒░░░░░░░░░░░░░░░█████▒░█▓░▒████▓▓░░░░░░░▒██████████▓▒░░░░░░░░░░░░░░░██████████████████████████████████▓▒░░░░░░░░░░░░░░░███████████████████████████████    //
//    ▓▒░░░░░░░░░░░░███████████████████████████████████████▓▒░░░░░░░░░░░▒██▒░░▒░░░▒█▓▒░░░░░░░░▒████████████████▒░░░░░░░░░░░░░█████████████████████████████████████▒░░░░░░░░░░░░░▓█████████████████████████████    //
//    ███▓░░░░░░░░░░██████████████████████████████████████████▓░░░░░░░░░░▓█▓▒█████▓▓▓░░░░░░░░▓████████████████████▓▒░░░░░░░░░░███████████████████████████████████████▓▒░░░░░░░░░░▒████████████████████████████    //
//    ██████▒░░░░░░░▓████████████████████████████████████████████▓▒░░░░░░░██████████▒░░░░░░▓██████████████████████████▓▒░░░░░░░██████████████████████████████████████████▓▒░░░░░░░░███████████████████████████    //
//    █████████▒░░░░▓███████████████████████████████████████████████▓▒░░░░▒████████▓░░░░░▒███████████████████████████████▓▒░░░░░█████████████████████████████████████████████▓▒░░░░░▓█████████████████████████    //
//    ███████████▓▒░▒██████████████████████████████████████████████████▓▒░░███████████▓▓█████████████████████████████████████▓▒░░████                                                                             //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SLxSW is ERC721Creator {
    constructor() ERC721Creator("Satria Lingga x Sigi Wimala", "SLxSW") {}
}