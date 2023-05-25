// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 3drinklunch
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//                                                         //
//                            .___                         //
//    ___  ______   ____    __| _/____   ____   _____      //
//    \  \/ /  _ \ /    \  / __ |/  _ \ /  _ \ /     \     //
//     \   (  <_> )   |  \/ /_/ (  <_> |  <_> )  Y Y  \    //
//      \_/ \____/|___|  /\____ |\____/ \____/|__|_|  /    //
//                     \/      \/                   \/     //
//                                                         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract threedrink is ERC1155Creator {
    constructor() ERC1155Creator("3drinklunch", "threedrink") {}
}