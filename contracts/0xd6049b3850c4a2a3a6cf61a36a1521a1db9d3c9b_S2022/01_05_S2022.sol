// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: I Survived... 2022
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//    ██████████████████████████████████████████████████████████████████████████████████████████████████████████████    //
//    ██████████████████████████████████████████████████████████████████████████████████████████████████████████████    //
//    ██████████████████████████████████████████████████████████████████████████████████████████████████████████████    //
//    ████████████▒░░██████▒░░░░▓█▓░░▓█▓░░█▓░░░░░▒▓█▒░▒███▒░▒▓░░▓▓░░███▓░░█░░░░░░░█▒░░░░░▒██████████████████████████    //
//    ████████████░░░█████░░░▓▒░░▓▒░░▓█░░░█▒░░▒▓░░░█░░░██▓░░▓▒░░▓▒░░▓██░░▒▓░░░▓▓▓▓█░░░▓▓░░░█████████████████████████    //
//    ████████████░░░████▓░░░██▓▓█░░░▓█░░░█▒░░▓█░░░█▓░░▓█▒░░█▓░░▓█░░░██░░▓█░░▒█████░░░██▒░░█████████████████████████    //
//    ████████████▒░░█████▓░░░▓███▒░░▓█▒░░█▒░░▒▓░░░██░░▒█░░░█▒░░▓█░░░█▒░░██░░░▒▒▒██░░░██░░░█████████████████████████    //
//    ████████████▓░░███████▓░░░▓██░░▒██░░▓█░░░░░░▒██▓░░▓░░░█▓░░▓█▓░░▓▒░▒██░░░▒▒▒██▒░░██▓░░█████████████████████████    //
//    ████████████▓░░▓████▓▓▓█▒░░▓▓░░▓█▓░░▓█░░▒█▓░░▓██░░▒░░▓██░░▒██░░░░░▒██░░░█████▒░░██▓░░▓████████████████████████    //
//    ████████████▓░░▓████░░▒█▓░░▒█░░▒█▓░░▓█░░▒██░░▓██░░░░░███░░▒██▒░░░░███░░░█████▒░░██▒░░█████████████████████████    //
//    ████████████▓░░▓████▓░░░░░▒██▒░░░░░▒█▓░░▓██░░▓██▒░░░▒██▓░░▓██▓░░░░███░░░░░░░█▒░░░░░░▓█▒░░█▒░░█▓░░▓████████████    //
//    ██████████████████████████████████████████████████████████████████████████████████████████████████████████████    //
//    ██████████████████████████████████████████████████████████████████████████████████████████████████████████████    //
//    █████████████████████████████████████████▓▒▓▓▒███▒▒▓▒▒██▒▒▓▓▒██▓▒▓▓▒▓█████████████████████████████████████████    //
//    █████████████████████████████████████████░▓███░█▒▒███▒▒█░███▓░█░▒███░▓████████████████████████████████████████    //
//    █████████████████████████████████████████████▓░█▒▒███▒▒█████▒░██████░█████████████████████████████████████████    //
//    ████████████████████████████████████████████▒▓██░████▒▓████▒▓█████▒▒██████████████████████████████████████████    //
//    ██████████████████████████████████████████▒▒████░████░▓█▓░▓█████▒▒████████████████████████████████████████████    //
//    █████████████████████████████████████████░▓████▓░▓███░▓▓░██████░▒█████████████████████████████████████████████    //
//    █████████████████████████████████████████░▓▓▓▓▓██▒▓▓▒▒█▓░▓▓▓▓▓█░▒▓▓▓▓█████████████████████████████████████████    //
//    ██████████████████████████████████████████████████████████████████████████████████████████████████████████████    //
//    ██████████████████████████████████████████████████████████████████████████████████████████████████████████████    //
//    ██████████████████████████████████████████████████████████████████████████████████████████████████████████████    //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract S2022 is ERC721Creator {
    constructor() ERC721Creator("I Survived... 2022", "S2022") {}
}