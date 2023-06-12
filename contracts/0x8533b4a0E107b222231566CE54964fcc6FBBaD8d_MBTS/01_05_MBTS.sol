// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Monster Blocks Theme Song by MC Faceman
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//    • ▌ ▄ ·.  ▄▄·   ·▄▄▄▄▄▄·  ▄▄· ▄▄▄ .• ▌ ▄ ·. ▄▄▄·  ▐ ▄       //
//    ·██ ▐███▪▐█ ▌▪  █  ·▐█ ▀█ ▐█ ▌▪▀▄.▀··██ ▐███▪▐█ ▀█ •█▌▐█    //
//    ▐█ ▌▐▌▐█·██ ▄▄  █▀▀▪▄█▀▀█ ██ ▄▄▐▀▀▪▄▐█ ▌▐▌▐█·▄█▀▀█ ▐█▐▐▌    //
//    ██ ██▌▐█▌▐███▌  ██ .▐█▪ ▐▌▐███▌▐█▄▄▌██ ██▌▐█▌▐█▪ ▐▌██▐█▌    //
//    ▀▀  █▪▀▀▀·▀▀▀   ▀▀▀  ▀  ▀ ·▀▀▀  ▀▀▀ ▀▀  █▪▀▀▀ ▀  ▀ ▀▀ █▪    //
//                                                                //
//    Monster Blocks Theme Song by MC Faceman, 2023.              //
//    Beat by Clever Neph.                                        //
//                                                                //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract MBTS is ERC721Creator {
    constructor() ERC721Creator("Monster Blocks Theme Song by MC Faceman", "MBTS") {}
}