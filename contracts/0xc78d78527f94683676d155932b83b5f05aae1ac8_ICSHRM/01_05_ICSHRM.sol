// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Ice Shroom
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    █████████████████████████████▓▓█████████████████████████████████████████████████████████████████████    //
//    ███████████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███████████████████████    //
//    █████████████████████████████████████▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓██████████████████    //
//    █████████████████████████████████▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓██████████████    //
//    ███████████████████████████████▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓███████████    //
//    █████████████████████████▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█████████    //
//    ████████████████████████▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓████████    //
//    █████████████████████▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓████████    //
//    ███████████████████▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░▒▒░░▒░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓████████    //
//    ████████████▓██▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▒░░░▒▒░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒▒▓▓▒▒▓█████████    //
//    █████████████▓██▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▒▒▒▒▒▒▒▒░▒▒░░░▒░░▒▒▒░▒▓▓█████████████    //
//    ████████████████▓▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒░▒░░░░░░░░▒░░▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▒▓▓▓▒▒░░░░░░░░░░░▒░▒▓▓▒▓███████████████    //
//    ██████████████████▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒░▒░▒░░░░░░░░░▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░▒▒▓▒▓███████████████████    //
//    ███████████████████▓▓▓▓▓▒▓▓▒▒▒▒▒▒▒▒░░░▒░░░▒░░▒▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░▒▒░▒▓▒▓██▓████████████████████    //
//    ██████████████████████████▓█▓▓▓▒▓▒▒▒▒░▒░░░░░▒▓▓▓▓██▓▓▓▓▓█▓▓▓▓▓▓█▒░▒▒▒▒▒▓▓▓▓▓▓███████████████████████    //
//    █████████████████████▓▓▒▒▒▒▓▓▒▓▓█▓▒▓▓▒▓▒▒▒░▒▓▓█▓████▓▓▓▓▓▓▓▓▓▓▓█▓▓▓██▓▓█████████████████████████████    //
//    ▓▓█████████▓▓█▓▓████▓▓▓▓▓▓▓▓▓▓▓█▓▓█▓█▓▓▓▓▒▓▓▓████████▓▓███▓▓▓▓█▓████████████████████████████████████    //
//    █████████████████████▓▓██▓▓▓▓▓▓▓████████▓▓▓▓▓███████████▓██████▓████████████████████████████████████    //
//    ▓▓▓▓▓█████████████████████████▓██████████▓▓█████████████████████████████████████████████████████████    //
//    ▓█▓▓▓▓▓▓▓▓▓▓▓██████████████████▓█████████▓████████████████████▓█████████████████████████████████████    //
//    ██▓▓████████▓▓▓█████████████▓▓▓█████████▓███████████████████████████████████████████████████████████    //
//    ▓▓▓▓▓▓▓▓▓▓▒▓▓▓▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▒▒▓▓██████▓█████████████████████▓██▓███████████████████████████████████    //
//    ███▓▓▓▓█▓▓▓▓▓▓▓▓▓██████████▓██▓▓▓███████████████████████████████████████████████████████████████████    //
//    ███████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████████████████████████▓▓▒▒▒▒▒▓▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▒▓▓▓▓▓▓▓▓█▓▓█▓▓█████▓▓██████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████████████████▓███▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▓▓▓▓▓▓▓▓▒▓▓▒▒▒▒▒▒▒▒▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓████▓▓▓▓▓▓▓▓▓▓████████████████████████████    //
//    █▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███████▓▓▓█████▓▓▓▓▓▓██▓███████▓█████████▓█████████    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓██████▓▓▓▓▓█▓▓▓▓▓▓██▓██████████████████▓▓▓▓▓▓▓█▓▓▓▓█████████▓█▓████████████    //
//    ▓▓▓▓▓▓▓▓▓▓█▓██████▓▓▓▓█▓▓▓▓███████▓▓▓▓▒▓▓▓▓▓▓▓█████████████████████████▓██▓▓████████████████████████    //
//    ▓▓▓▓██▓▓▓██▓▓████▓▓▓▒▓▓▓▓▓▓█████████▓▓▓▓▓▓▓▓██████████████████████▓███████████████▓█████████████████    //
//    ███████▓▓██▓█████▓▒▓▒▒▓▒▒▓██████▓▓▓▓▓▓▓▓▓▓▓████████████████████████▓████████████████████████████████    //
//    ▓▓▓██████████████▓▓▓▓▓▓▒▓▓▓██████▓█▓▓▓▓▓▓▓████████████████████████▓█████████████████████████████████    //
//    █████████████████████▓▓▓▓██████▓▓▓▓▓▓▓▒▒▒▒▓██████████████████████▓▒▓▓▓▓▓▓███████████████████████████    //
//    ███████████████████▓▓▓▓▓▓█████▓▓▓▓▓▓▓▒▒▒▒▒▓▓█████████████████████▓▓▓▓▓▓▓████████████████████████████    //
//    ████████████████████████████▓▓▓▓▓▒▒▒▒▒▒▒▒▒▓▓█████████████████████▓▒▒▓▓▓▓▓▓▓██████████▓▓▓████████████    //
//    ███████████████████████████▓▓▓▓▒▒▓▒▒▒▒▒▒▒▒▒▒▓▓███████████████████▓▒▒▒▒▒▒▒▓▓▓▓▓▓▓█████████▓█▓▓███████    //
//    ██████████████████████████▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▓▓▓███████████████████▓▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓████████████████    //
//    █████████████████████████████▓▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓████████████████████▓▒▒▒▒▒▒▓▓▓▒▒▒▓▓▓▓▓▓███████████████    //
//    ███████████████████████▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▓▒▓▓█████████████████████▓▓▓▓▒▒▒▓▓▓▓▓▓▓▓▓▓▓████████████████    //
//    ██████████████████████▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▓▓▓▓▓█████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███████████████    //
//    ███████████████████████▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▓▓▓▓██████▓█████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███████████████    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ICSHRM is ERC1155Creator {
    constructor() ERC1155Creator("The Ice Shroom", "ICSHRM") {}
}