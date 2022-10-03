// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Stoned Relic Faces Of MetaBert
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//        /|    //| |                                //
//       //|   // | |     ___    __  ___  ___        //
//      // |  //  | |   //___) )  / /   //   ) )     //
//     //  | //   | |  //        / /   //   / /      //
//    //   |//    | | ((____    / /   ((___( (       //
//                                                   //
//        //   ) )                                   //
//       //___/ /   ___      __    __  ___           //
//      / __  (   //___) ) //  ) )  / /              //
//     //    ) ) //       //       / /               //
//    //____/ / ((____   //       / /                //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract Bert is ERC721Creator {
    constructor() ERC721Creator("The Stoned Relic Faces Of MetaBert", "Bert") {}
}