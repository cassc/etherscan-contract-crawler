// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Who Do I Follow Bidders Edition
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//    ███████████████████▓██████████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████    //
//    ██████████████████▓▓██████████████████████████████████████████████████▓█▓▓██████████▓▓██████████████    //
//    ███████████████████▓████████████████████████████████████████████████████████████████████████████████    //
//    ████████████████████████████████████████████████████████████████████████████████████████████████████    //
//    ████████████████████████████████████████████████████████████████████████████████████████████████████    //
//    ████████████████████████████████████████████████████████████████████████████████████████████████████    //
//    █████████████████████████████████▓██▓███████████████▓▓▓▓▓▓▓▓▓███████████████████████████████████████    //
//    ██████████████████████████████▓▓▓▓▓▓███████████████████▓▓▓▓█████████████████████████████████████████    //
//    █████████████████████████████████▓▓▓▓▓█████▓▓████▓▓████▓█▓▓▓▓▓██████████████████████████████████████    //
//    ██████████████████████████████▓▓▓▓▓███▓▓▓▓▓▓▓▓█████▓███████████▓████████████████████████████████████    //
//    █████████████████████████▓▓██▓██▓▓▓▓▓▒▒███▓▒▓▓▓▓██████▓███▓█████▓▓▓█████████████████████████████████    //
//    ████████████████████████▒▓▓█▓▓▓▓▓▓▒▒▒▒▒▓▓▓▒▓██▓▒▓▓▓███▓▓▓▓▓▓▓▓▓▓█▓▓▓████████████████████████████████    //
//    █████████████████████▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▒▓▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███████████████████████████    //
//    █████████████████████▓▓▓█▓▓█▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓███████████████████████    //
//    █████████████████████▓▓▓▓▓▓▓██▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▓▓█▓▓▓▓▓██▓▓█▓▓▓▓▓▓▓▓▓▓▓▓███▓██████████████████████    //
//    █████████████████████▓█▓▓███▓█▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████▓██▓▓█▓▓█▓▓▓██▓▓███▓▓██▓█████████████████████▓    //
//    █████████████████████▓███████▓▓▓███▓▓▓▓▓▓▓▓▓▓▓▓▓▒▓███▓███▓▓▓▓▓▓██▓█▓▓▓██▓▓▓█████████████████████████    //
//    ██████████████████████▓████▓█▓▓▓██▓▓▓▓▓▓██▓▓▓▓▓▓▓█▓▓███▓▓████▓▓███████▓▓████████████████████████████    //
//    ███████████████████████▓▓█▓▓█▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓█████▓▓▓▓▓█▓▓███▓▓▓██████████████████████████    //
//    █████████████████████████▓▓▓▓▓██▓▓▓▓██▓▓▓█████▓▓▓▓▓▓▓▓██▓▓████████▓▓▓▓█▓▓▓██████████████████████████    //
//    ███████████████████████▓▓▓▓▓█▓▓██████▓▓▓▓▓▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓████▓▒██▓███████████████████████████    //
//    █████████████████████▓██▓▓█▓▓█▓▓▓▓█▓▓▓▓▓▓██████████▓▓▓▓▓▓███▓▓▓▓▓████▓▓█████████████████████████████    //
//    █████████████████████▓▓▓███▓▓▓▓▓▓█▓▓▓▓█▓▓██▓▓▓▓▓▓▓███▓▓████▓▓▓▓▓▓▓▓▓▓▓██████████████████████████████    //
//    ██████████████████████▓▒▓██▓▓▓▓▓██▓▓▓▓█▓▓███▓▓▓▓▓▓▓▓██████▓▓▓▓██▓▓▓▓▓███████████████████████████████    //
//    ███████████████████████▓▓▓▓▓▓▓▓████▓▓▓▓▓██▓▓███████████▓█▓▓▓▓███▓█▓▓████████████████████████████████    //
//    █████████████████████████████▓▓▓████▓▓▒▓███▓▓▓▓█▓▓▓▓█▓██▓▓▓█████████████████████████████████████████    //
//    █████████████████████████▓▓███▓▓▓▓▓███▓▓▓████▓▓▓▓▓█████▓▓▓▓███▓▓▓▓▓█████████████████████████████████    //
//    ██████████████████████████▓███▓▓▓▓▓▓██▓▓▓▓▓▓▓▓▓▓▓▓█▓██▓▓▓▓▓█████████████████████████████████████████    //
//    █████████████████████████▓▓████▓▓▓▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓████████████████████████████████████████    //
//    ▓█▓██████████████████████▓██████▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████▓▓▓█▓▓▓▓▓█████████████████████████████████████    //
//    ▓▓▓▓▓▓▓▓█████████████▓██▓▓███████▓▓▓▓▒▓▓▓████████▓▓██▓▓▓█▓▓▓████████████████████████████████████████    //
//    ▓▓▓▓▓▓▓▓▓█▓▓████████▓█▓▓███████▓█▓▓▓▒▒▓████▓█▓▓██████▓▓▓██▓█▓███████████████████████████████████████    //
//    ▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓███▓██▓██▓██▓███▓▓▓▓▒▓█▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓███▓█████████████████████████████████████████    //
//    █████▓█▓▓▓▓████████▓█▓▓██▓███▓███▓▓▓▓▓▓█████▓▓▓▓▓▓████▓▓▓▓██████████████████████████████████████████    //
//    ██████████████████▓▓██▓██████▓████▓▓▓▓▓▓██▓▓▓███▓██▓▓███████████████████████████████████████████████    //
//    ██████████████████▓▓▓█▓███▓██▓███▓▓▓▓▓▓▓▓██▓▓▓▓▓▒▓▓█████████████████████████████████████████████████    //
//    █████████████▓████▓▓███▓██▓██▓███▓▓█▓▓▓▓▓███▓▓▓▓▓▓▓█████████████████████████████████████████████████    //
//    █████████████▓▓██▓▓██▓▓███▓██▓▓▓▒▒███▓▓██▓▓▓▓▓██████████████████████████████▓███████████████████████    //
//    ██████████████▓▓▓▓██▓▓▓█████▓▓▓▓▓▓▓████▓▓▓▓▓▓▓▓▓████████████████████████████▓███████████████████████    //
//    ██▓▓▓█████▓▓▓█▓▓▓▓█▓▓▓▓█████▓▓▓▓▓▓█▓▓▓█████▓█▓█████▓████████████████████████████████████████████████    //
//    █▓████▓▓█▓▓▓██▓██▓▓▓███▓████▓▓▓▓██▓▓▓▓▓▓▓██▓▓▓▓▓██████▓█████████████████████████████████████████████    //
//    █▓▓▓▓▓▓▓▓▓████████▓▓▓▓▓▓▓▓█▓▓▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████▓▓█████████████████████████████████████████████    //
//    ██████████▓█▓█████▓▓▓▓▓▓▓▓█▓▓▓▓██▓▓▓▓▓▒▒▒▓▓▓▓▓██▓██▓▓▓█▓▓▓▓▓██▓█████████████████████████████████████    //
//    █████████████▓▓█▓▓███▓▓▓▓▓▓█▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓██▓██▓▓▓█████████████▓▓▓███████████████████████████████    //
//    █▓████████████████▓▓▓▓▓▓▓▓█▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▓▓▓████████████████████▓▓████████████████████████    //
//    ▓▓▓████▓▓████████████████▓▓▓▓█████▓▓▓▓▓▒▓▓▓▓▓███▓▓███████████████▓▓▓▓▓▓▓▓▓▓▓▓███████████████████████    //
//    ▓▓▓███▓▓▓▓▓██████▓▓▓▓▓▓████▓▓▓█▓▓███▓▓▓▒▓▓████▓▓███████▓▓▓▓▓▓▓▓██████▓▓▓▓███▓██▓▓██████▓▓███████████    //
//    ▓█████▓▓▓▓▓▓█████▓▓▓▓▓▓▓████▓▓▓███▓▓██▓▓██▓▓▓▓▓███▓▓▓▓▓▓▓▓▓███▓▓▓▓▓▓▓▓▓█▓▓▓▓█▓█▓██▓▓▓██▓▓▓██████████    //
//    ▓▓█▓█▓▓▓▓▓▓▓▓▓████▓▓▓▓▓▓▓█████▓▓▓███▓███████▓▓▓▓▓▓▓▓▓▓▓█████▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓█▓▓██▓▓▓▓▓█▓▓▓▓█████████    //
//    ██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████▓▓▓█▓▓███▓▓▓▓▓█▓▓▓████▓▓▓▓▓▓███▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▓▓▓██▓▓▓▓▓███████    //
//    ██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████▓▓▓▓██▓▒▓▓██████▓▓▓▓▓▓▓▓▓████▓▓▓▓▓▓▓█▓▓▓▓▓▓▓███▓▓▓▓▓███▓▓▓███████    //
//    █▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████▓▓▓▓▓▓▒▓▓███████▓▓▓▓▓██████▓▓▓▓▓▓▓▓▓██▓▓██▓▓████▓▓█▓▓▓██▓▓███████    //
//    ▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓███▓▓▓██▓▓▓▓█▓▓▓▓██████████████▓▓▓▓▓▓▓▓▓▓▓████▓███████▓▓▓▓▓█▓▓███████    //
//    ▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓███▓▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓█▓▓▓▓████████████▓▓▓▓▓▓██▓███████    //
//    ▓▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓████▓▓▓██▓████████████▓▓▓▓▓█████▓▓▓▓████████████████▓▓▓▓▓▓███████    //
//    ▓▓███▓▓▓▓▓██▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███▓▓▓▓██████▓████████████████▓▓▓▓▓███████████▓▓▓▓▓█▓▓▓▓▓███████    //
//    ▓▓▓███▓▓▓▓████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███▓▓▓▓██████████████████▓▓▓▓▓▓▓██▓▓▓███████▓▓▓▓▓▓▓▓█▓▓▓▓███████    //
//    ▓▓▓▓███████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓██▓▓███▓█████▓▓▓▓▓▓▓▓▓▓█████████████▓██▓▓▓▓▓▓▓▓▓▓█▓▓▓███████    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SOUL is ERC721Creator {
    constructor() ERC721Creator("Who Do I Follow Bidders Edition", "SOUL") {}
}