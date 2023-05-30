// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WHAT THE FOOD
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
//        //    //    W     W H  H  AA  TTTTTT     TTTTTT H  H EEEE     FFFF  OOO   OOO  DDD          //    //    //
//       //    //     W     W H  H A  A   TT         TT   H  H E        F    O   O O   O D  D        //    //     //
//      //    //      W  W  W HHHH AAAA   TT         TT   HHHH EEE      FFF  O   O O   O D  D       //    //      //
//     //    //        W W W  H  H A  A   TT         TT   H  H E        F    O   O O   O D  D      //    //       //
//    //    //          W W   H  H A  A   TT         TT   H  H EEEE     F     OOO   OOO  DDD      //    //        //
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WTF is ERC721Creator {
    constructor() ERC721Creator("WHAT THE FOOD", "WTF") {}
}