// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EASYSTYLE Manifold Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                                                                      //
//                                                                                      //
//                (       ) (              ) (                                          //
//          (     )\ ) ( /( )\ )  (   ) ( /( )\ )                                       //
//     (    )\   (()/( )\()|()/(` )  /( )\()|()/( (                                     //
//     )\((((_)(  /(_)|(_)\ /(_))( )(_)|(_)\ /(_)))\                                    //
//    ((_))\ _ )\(_))__ ((_|_)) (_(_())_ ((_|_)) ((_)                                   //
//    | __(_)_\(_) __\ \ / / __||_   _\ \ / / |  | __|                                  //
//    | _| / _ \ \__ \\ V /\__ \  | |  \ V /| |__| _|                                   //
//    |___/_/ \_\|___/ |_| |___/  |_|   |_| |____|___|                                  //
//                                                                                      //
//                                                                                      //
//    Buying art under this contract you have the right to use it to your advantage.    //
//                                                                                      //
//    With respect and love. Your Ezzie                                                 //
//                                                                                      //
//                                                                                      //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////


contract EZZY is ERC721Creator {
    constructor() ERC721Creator("EASYSTYLE Manifold Editions", "EZZY") {}
}