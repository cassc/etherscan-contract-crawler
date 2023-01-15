// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: We Live In A SlaughterHouse
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//                                          //
//      ___ ___                     .__     //
//     /   |   \  ____  __ _________|__|    //
//    /    ~    \/  _ \|  |  \_  __ \  |    //
//    \    Y    (  <_> )  |  /|  | \/  |    //
//     \___|_  / \____/|____/ |__|  |__|    //
//           \/                             //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract Freak is ERC721Creator {
    constructor() ERC721Creator("We Live In A SlaughterHouse", "Freak") {}
}