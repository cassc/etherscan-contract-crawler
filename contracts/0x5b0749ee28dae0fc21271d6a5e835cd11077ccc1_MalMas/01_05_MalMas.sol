// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MalaChristmas 2022
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//      *  /\   *       //
//        /__\ *        //
//    * (______)   *    //
//    (\)_i__i_(/)      //
//      <\  V />        //
//                      //
//                      //
//////////////////////////


contract MalMas is ERC721Creator {
    constructor() ERC721Creator("MalaChristmas 2022", "MalMas") {}
}