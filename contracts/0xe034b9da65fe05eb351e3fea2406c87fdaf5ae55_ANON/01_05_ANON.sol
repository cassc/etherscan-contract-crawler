// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ANONS by Matt Kane
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//      The past and present wilt--I have fill’d them, emptied them.                 //
//      And proceed to fill my next fold of the future.                              //
//                                                                                   //
//      Listener up there! what have you to confide to me?                           //
//      Look in my face while I snuff the sidle of evening,                          //
//      (Talk honestly, no one else hears you, and I stay only a minute longer.)     //
//                                                                                   //
//      Do I contradict myself?                                                      //
//      Very well then I contradict myself,                                          //
//      (I am large, I contain multitudes.)                                          //
//                                                                                   //
//      I concentrate toward them that are nigh, I wait on the door-slab.            //
//                                                                                   //
//      Who has done his day’s work? who will soonest be through with his supper?    //
//      Who wishes to walk with me?                                                  //
//                                                                                   //
//      Will you speak before I am gone? will you prove already too late?            //
//                                                                                   //
//      —Walt Whitman, Song of Myself, 1892                                          //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract ANON is ERC721Creator {
    constructor() ERC721Creator("ANONS by Matt Kane", "ANON") {}
}