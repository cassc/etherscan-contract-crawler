// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shallow Whispers
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                            //
//                                                                                                                            //
//    “The sunrise peeled back the layers of shadow set upon the water.  An endless void gave way to an infinite horizon.”    //
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
//                           o   o                                                                                            //
//                              .                                                                                             //
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
//                                                      O    o                                                                //
//                                                        .                                                                   //
//                                                                                                                            //
//                                                                                                                            //
//                         o o                                                                                                //
//                          _                                                                                                 //
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
//                                                          o o                                                               //
//                                                            ...                                                             //
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
//                o   o                                                                                                       //
//                  .                                                                                                         //
//                                                                                                                            //
//                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WHISPERS is ERC721Creator {
    constructor() ERC721Creator("Shallow Whispers", "WHISPERS") {}
}