// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FinishWhatYouStart
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//              ___   ___          ___   ___                         //
//        //   / / / /    /|    / /   / /    //   ) )  //    / /     //
//       //___    / /    //|   / /   / /    ((        //___ / /      //
//      / ___    / /    // |  / /   / /       \\     / ___   /       //
//     //       / /    //  | / /   / /          ) ) //    / /        //
//    //     __/ /___ //   |/ / __/ /___ ((___ / / //    / /         //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract FINISH is ERC721Creator {
    constructor() ERC721Creator("FinishWhatYouStart", "FINISH") {}
}