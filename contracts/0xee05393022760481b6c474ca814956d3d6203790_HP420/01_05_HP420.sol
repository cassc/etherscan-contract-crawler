// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alea jacta est
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//      ____                                                                             //
//     /\' .\    _____                                                                   //
//    /: \___\  / .  /\                                                                  //
//    \' / . / /____/..\                                                                 //
//     \/___/  \'  '\  /                                                                 //
//              \'__'\/                                                                  //
//                                                                                       //
//    This contract contains original @honeypepp3r artwork based non fungible tokens.    //
//                                                                                       //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract HP420 is ERC721Creator {
    constructor() ERC721Creator("Alea jacta est", "HP420") {}
}