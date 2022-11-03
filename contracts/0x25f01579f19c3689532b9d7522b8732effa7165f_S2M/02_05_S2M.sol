// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shortcut2Manifold
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    ░█▒█░█▄░█░█░▀█▀░▀▄▀░░░▄▀▄▒█▀░░░█▄▒▄█░█▒█░█▒░░▀█▀░█    //
//    ░▀▄█░█▒▀█░█░▒█▒░▒█▒▒░░▀▄▀░█▀▒░░█▒▀▒█░▀▄█▒█▄▄░▒█▒░█    //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract S2M is ERC721Creator {
    constructor() ERC721Creator("Shortcut2Manifold", "S2M") {}
}