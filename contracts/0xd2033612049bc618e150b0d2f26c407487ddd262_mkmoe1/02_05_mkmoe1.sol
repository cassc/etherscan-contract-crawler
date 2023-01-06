// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Makam.OE.1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                                               //
//    ___  ___        _                          //
//    |  \/  |       | |                         //
//    | .  . |  __ _ | | __  __ _  _ __ ___      //
//    | |\/| | / _` || |/ / / _` || '_ ` _ \     //
//    | |  | || (_| ||   < | (_| || | | | | |    //
//    \_|  |_/ \__,_||_|\_\ \__,_||_| |_| |_|    //
//                                               //
//                                               //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract mkmoe1 is ERC721Creator {
    constructor() ERC721Creator("Makam.OE.1", "mkmoe1") {}
}