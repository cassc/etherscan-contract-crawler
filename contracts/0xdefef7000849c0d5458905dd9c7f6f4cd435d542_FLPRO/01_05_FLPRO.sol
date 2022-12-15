// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Prologue: A Visual Album Experience
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//     ________   .---.       ____..--'     //
//    |        |  | ,_|      |        |     //
//    |   .----',-./  )      |   .-'  '     //
//    |  _|____ \  '_ '`)    |.-'.'   /     //
//    |_( )_   | > (_)  )       /   _/      //
//    (_ o._)__|(  .  .-'     .'._( )_      //
//    |(_,_)     `-'`-'|___ .'  (_'o._)     //
//    |   |       |        \|    (_,_)|     //
//    '---'       `--------`|_________|     //
//                                          //
//                                          //
//////////////////////////////////////////////


contract FLPRO is ERC721Creator {
    constructor() ERC721Creator("Prologue: A Visual Album Experience", "FLPRO") {}
}