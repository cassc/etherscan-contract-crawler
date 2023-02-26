// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: UNSUB
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//     __ __  ____    _____ __ __  ____      //
//    |  T  T|    \  / ___/|  T  T|    \     //
//    |  |  ||  _  Y(   \_ |  |  ||  o  )    //
//    |  |  ||  |  | \__  T|  |  ||     T    //
//    |  :  ||  |  | /  \ ||  :  ||  O  |    //
//    l     ||  |  | \    |l     ||     |    //
//     \__,_jl__j__j  \___j \__,_jl_____j    //
//                                           //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract UNSUB is ERC721Creator {
    constructor() ERC721Creator("UNSUB", "UNSUB") {}
}