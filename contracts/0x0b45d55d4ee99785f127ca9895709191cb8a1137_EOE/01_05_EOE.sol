// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Elliot’s OE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    ╔═══╦╗╔╗────╔╗     //
//    ║╔══╣║║║───╔╝╚╗    //
//    ║╚══╣║║║╔╦═╩╗╔╝    //
//    ║╔══╣║║║╠╣╔╗║║     //
//    ║╚══╣╚╣╚╣║╚╝║╚╗    //
//    ╚═══╩═╩═╩╩══╩═╝    //
//                       //
//                       //
///////////////////////////


contract EOE is ERC721Creator {
    constructor() ERC721Creator(unicode"Elliot’s OE", "EOE") {}
}