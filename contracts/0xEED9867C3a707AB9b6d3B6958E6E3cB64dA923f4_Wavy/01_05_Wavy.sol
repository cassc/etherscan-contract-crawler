// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wavy
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                                   //
//     __    __                      //
//    / / /\ \ \__ ___   ___   _     //
//    \ \/  \/ / _` \ \ / / | | |    //
//     \  /\  / (_| |\ V /| |_| |    //
//      \/  \/ \__,_| \_/  \__, |    //
//                         |___/     //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract Wavy is ERC1155Creator {
    constructor() ERC1155Creator("Wavy", "Wavy") {}
}