// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gratitude
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//      ___ ____  __ ____ __ ____ _  _ ____ ____     //
//     / __|  _ \/ _(_  _|  |_  _) )( (    (  __)    //
//    ( (_ \)   /    \)(  )(  )( ) \/ () D () _)     //
//     \___(__\_)_/\_(__)(__)(__)\____(____(____)    //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract YLW is ERC1155Creator {
    constructor() ERC1155Creator("Gratitude", "YLW") {}
}