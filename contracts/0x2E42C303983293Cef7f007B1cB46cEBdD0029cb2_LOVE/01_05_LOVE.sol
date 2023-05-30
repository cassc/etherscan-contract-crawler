// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Give Love
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                                      //
//      ___ ____      ____    __     ___       ____     //
//     //    ((\\    ((        ))  //  )))   //(        //
//    // __  )) \\  //))_     //  //  //\\  // ))_      //
//    ((__//_((_ \\//((__    ((__((__//  \\// ((__      //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract LOVE is ERC1155Creator {
    constructor() ERC1155Creator("Give Love", "LOVE") {}
}