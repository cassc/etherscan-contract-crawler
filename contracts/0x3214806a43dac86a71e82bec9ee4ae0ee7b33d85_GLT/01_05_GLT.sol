// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Glitch
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    ░▄▀▒░█▒░░█░▀█▀░▄▀▀░█▄█    //
//    ░▀▄█▒█▄▄░█░▒█▒░▀▄▄▒█▒█    //
//                              //
//                              //
//////////////////////////////////


contract GLT is ERC721Creator {
    constructor() ERC721Creator("Glitch", "GLT") {}
}