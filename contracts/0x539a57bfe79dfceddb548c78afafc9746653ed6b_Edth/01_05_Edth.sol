// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Edith
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    ▒▒▒▒▒▒▐███████▌          //
//    ▒▒▒▒▒▒▐░▀░▀░▀░▌          //
//    ▒▒▒▒▒▒▐▄▄▄▄▄▄▄▌          //
//    ▄▀▀▀█▒▐░▀▀▄▀▀░▌▒█▀▀▀▄    //
//    ▌▌▌▌▐▒▄▌░▄▄▄░▐▄▒▌▐▐▐▐    //
//                             //
//                             //
/////////////////////////////////


contract Edth is ERC721Creator {
    constructor() ERC721Creator("Edith", "Edth") {}
}