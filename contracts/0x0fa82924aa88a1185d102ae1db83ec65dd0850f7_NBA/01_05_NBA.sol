// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pieces of My Life - Nick Beckner Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//    this is a collection of pieces created by nick beckner.         //
//    these pieces symbolize my mind and heart at any given time.     //
//    this collection will continue to grow until i die.              //
//    then it's my son's job to pick up what i left.                  //
//    -2022 nick beckner                                              //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract NBA is ERC721Creator {
    constructor() ERC721Creator("Pieces of My Life - Nick Beckner Art", "NBA") {}
}