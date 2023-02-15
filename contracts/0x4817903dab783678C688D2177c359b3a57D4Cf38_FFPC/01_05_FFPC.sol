// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fast Food Punks Combo
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//    llllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllc::::::::::::::clllllllllllllllll    //
//    lllllllllllllc:,';:;,;:;,''''';:clllllllllllllll    //
//    lllllllllllc:,',:lolclolc:;'''',;:clllllllllllll    //
//    llllllllllc;..'cxl,lxl,lxxl,''''',:lllllllllllll    //
//    lllllc:::::,..':l;':l:':ll:''''''':cllllllllllll    //
//    lllll:;;;;;'.;lllllllllllllccllc;.,cllllllllllll    //
//    llllllllc:,. ,oddddddddddddddddo, .cllllllllllll    //
//    llllllc:,,,. .,;,.   .,;;,;,.     .cllllllllllll    //
//    llllllc,.;oc;dXNXc   cKNNNNXc     .cllllllllllll    //
//    llllllllc' ,d0NNNx;,;xXNXXNXx;,'. .cllllllllllll    //
//    llllllllc,.  lXNNNNNNNNX00XNNNNXc .cllllllllllll    //
//    llllllllllc. cXNNNNNNNNX00XNNNNXc .cllllllllllll    //
//    llllllllllc. cXNNNNNNNNXKKXNNNNXc .cllllllllllll    //
//    llllllllllc. cXNNNN0xxddxxxxxx0Xc .cllllllllllll    //
//    llllllllllc. cXNNNNx;,,;;;;,;;xXc .cllllllllllll    //
//    llllllllllc. cXNNNNNNNNNNNNNNX0d:.,cllllllllllll    //
//    llllllllllc. cXNNNN0xxdxxxxxxd:.,cllllllllllllll    //
//    llllllllllc. cXNNWXl  ........,cllllllllllllllll    //
//    llllllllllc. cXNNNXc .cllcccccllllllllllllllllll    //
//    llllllllllc. cXNNNXc .clllllllllllllllllllllllll    //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract FFPC is ERC1155Creator {
    constructor() ERC1155Creator("Fast Food Punks Combo", "FFPC") {}
}