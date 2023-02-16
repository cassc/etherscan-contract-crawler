// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Modern Lines
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    ___          //
//    | | I        //
//    | | N        //
//    | | E        //
//    | | S        //
//    | |______    //
//    |_______|    //
//                 //
//                 //
/////////////////////


contract AJB is ERC721Creator {
    constructor() ERC721Creator("Modern Lines", "AJB") {}
}