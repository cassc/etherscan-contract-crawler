// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Moments in Time
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                              //
//                                                                                              //
//     "The two most powerful warriors are patience and time." – Leo Tolstoy, War and Peace.    //
//                                                                                              //
//     "Better three hours too soon than a minute too late." – William Shakespeare.             //
//                                                                                              //
//     "Lost time is never found again." – Benjamin Franklin.                                   //
//                                                                                              //
//     "Time is the most valuable thing a man can spend." – Theophrastus.                       //
//                                                                                              //
//    Here you are - you've found me...welcome!                                                 //
//                                                                                              //
//    Here we both are, in the pre-January/02/2023 era - that demarcation in time where         //
//    certain marketplaces seek to impose restrictions...and here I am, wanting to freely       //
//    share art, while you're looking to explore the same.                                      //
//                                                                                              //
//    Here you'll find explorations in my journey - studies, thoughts, curiosities...           //
//    points on a timeline of artistic exploration and expression.                              //
//                                                                                              //
//    I hope that you enjoy what you find here, stay as long as you like.                       //
//                                                                                              //
//    Love to all, and to a bright future for everyone.                                         //
//                                                                                              //
//                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////


contract MIT is ERC721Creator {
    constructor() ERC721Creator("Moments in Time", "MIT") {}
}