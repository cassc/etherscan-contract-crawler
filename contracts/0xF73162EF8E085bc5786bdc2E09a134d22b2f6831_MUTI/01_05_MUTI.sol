// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Marquette University today is
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                  //
//                                                                                                                                  //
//    Is it not lonely?                                                                                                             //
//                                                                                                                                  //
//                                                                                                                                  //
//                                                                                                                                  //
//    It's been 25 years since Coach McGwire took the title in 1977 and quit.                                                       //
//                                                                                                                                  //
//                                                                                                                                  //
//                                                                                                                                  //
//    The best Marquette University has done this time is reach the third round of the tournament, the Sweet 16, and only twice.    //
//                                                                                                                                  //
//                                                                                                                                  //
//                                                                                                                                  //
//    Most of the time Marquette was either eliminated in the first round or didn't even qualify for the first round.               //
//                                                                                                                                  //
//                                                                                                                                  //
//                                                                                                                                  //
//    It's fair to say that Marquette University is definitely one of the NCAA's most troubled championship teams right now.        //
//                                                                                                                                  //
//                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MUTI is ERC721Creator {
    constructor() ERC721Creator("Marquette University today is", "MUTI") {}
}