// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lucid Psychedelic Abstractions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//                                      \\\\\  ////             //
//                                           ////               //
//                                       \\\\ ////              //
//                                  ====   ^^^^^^^              //
//                                {           ^ ^ ^             //
//                                {  &      :;:    ^ ^          //
//                                {          '       ^//////    //
//                                     [               /        //
//                                     ]      `````   /         //
//                                     [       ^^  /            //
//                                     ]         /              //
//                                       ///////                //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract LPA is ERC721Creator {
    constructor() ERC721Creator("Lucid Psychedelic Abstractions", "LPA") {}
}