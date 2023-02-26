// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Unclear Future of NFT
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//       __  ___   __________    _________    ____     //
//      / / / / | / / ____/ /   / ____/   |  / __ \    //
//     / / / /  |/ / /   / /   / __/ / /| | / /_/ /    //
//    / /_/ / /|  / /___/ /___/ /___/ ___ |/ _, _/     //
//    \____/_/ |_/\____/_____/_____/_/  |_/_/ |_|      //
//                                                     //
//    ===========================================      //
//                                                     //
//    The future of NFT is unclear.                    //
//                                                     //
//    This does not affect cryptoart in any way.       //
//                                                     //
//    Please return to your regularly scheduled        //
//    collecting of dank cryptoart.                    //
//                                                     //
//    (you can also buy this art too)                  //
//                                                     //
//    -obxium                                          //
//    20232                                            //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract UNCLEAR is ERC1155Creator {
    constructor() ERC1155Creator("Unclear Future of NFT", "UNCLEAR") {}
}