// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Aristhodlic Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//                  _________      //
//                 {_________}     //
//                  )=======(      //
//                 /  JPEGs  \     //
//                | _________ |    //
//                ||   _     ||    //
//                ||  |_)    ||    //
//                ||  | \/   ||    //
//          __    ||    /\   ||    //
//     __  (_|)   |'---------'|    //
//    (_|)        `-.........-'    //
//                                 //
//                                 //
/////////////////////////////////////


contract AA is ERC721Creator {
    constructor() ERC721Creator("Aristhodlic Art", "AA") {}
}