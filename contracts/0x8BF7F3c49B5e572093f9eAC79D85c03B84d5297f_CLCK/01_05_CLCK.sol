// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rainbow Clock
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//        _______   ______    _______  ____ ___     //
//      //       \//      \ //       \/    /   \    //
//     //        //       ///        /         /    //
//    /       --/        //       --//       _/     //
//    \________/\________/\________/\\___/___/      //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract CLCK is ERC721Creator {
    constructor() ERC721Creator("Rainbow Clock", "CLCK") {}
}