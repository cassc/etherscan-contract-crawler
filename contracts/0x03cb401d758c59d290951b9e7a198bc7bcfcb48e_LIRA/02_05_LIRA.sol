// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LIRA
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//     __                         __              //
//    |  | ______   _____   ____ |  | ______      //
//    |  |/ /  _ \ /     \_/ __ \|  |/ /  _ \     //
//    |    <  <_> )  Y Y  \  ___/|    <  <_> )    //
//    |__|_ \____/|__|_|  /\___  >__|_ \____/     //
//         \/           \/     \/     \/          //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract LIRA is ERC721Creator {
    constructor() ERC721Creator("LIRA", "LIRA") {}
}