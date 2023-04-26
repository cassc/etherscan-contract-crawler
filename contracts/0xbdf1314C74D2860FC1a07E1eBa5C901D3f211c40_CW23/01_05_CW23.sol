// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Carlitos II
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//                    .-.                                   .--.      //
//                   /  \\                                 /    \     //
//              .---/-+--||                               |      |    //
//              |  K=====++->                             |  O   |    //
//              '---\-+--||                               |      |    //
//                   \  //                                 \    /     //
//                    `-'                                   '--'      //
//    Pete                                                            //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract CW23 is ERC1155Creator {
    constructor() ERC1155Creator("Carlitos II", "CW23") {}
}