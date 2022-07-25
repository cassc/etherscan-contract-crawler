// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: colleagues say things
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                      //
//    He didn't get it at first.                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                      //
//    In order to have a common topic and good relations with colleagues, he first made up the movie on the broken computer, think good, American blockbuster is exciting.                                                              //
//                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                      //
//    At first, he couldn't tell the difference between Marvel and DC, but after reading more, he even memorized the names and abilities of hundreds of heroes and villains, as well as the important stories they were involved in.    //
//                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CST is ERC721Creator {
    constructor() ERC721Creator("colleagues say things", "CST") {}
}