// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OE X MT
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                  __          .__     //
//      ____   _____   ____   _____/  |_  _____ |__|    //
//    _/ __ \ /     \ /  _ \ /  _ \   __\/     \|  |    //
//    \  ___/|  Y Y  (  <_> |  <_> )  | |  Y Y  \  |    //
//     \___  >__|_|  /\____/ \____/|__| |__|_|  /__|    //
//         \/      \/                         \/        //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract EMOOTMI is ERC1155Creator {
    constructor() ERC1155Creator("OE X MT", "EMOOTMI") {}
}