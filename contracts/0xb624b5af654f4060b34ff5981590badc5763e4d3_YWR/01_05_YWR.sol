// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: YOWARAB
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//     _  _ _____ _    _   __   ____   __   ____     //
//    ( \/ (  _  ( \/\/ ) /__\ (  _ \ /__\ (  _ \    //
//     \  / )(_)( )    ( /(__)\ )   //(__)\ ) _ <    //
//     (__)(_____(__/\__(__)(__(_)\_(__)(__(____/    //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract YWR is ERC721Creator {
    constructor() ERC721Creator("YOWARAB", "YWR") {}
}