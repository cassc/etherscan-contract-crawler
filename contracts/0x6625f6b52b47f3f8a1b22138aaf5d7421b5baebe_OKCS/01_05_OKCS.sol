// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ON-KO-CHI-SHIN
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//                              //
//        __ __ __  __ ____     //
//        || || ||\ || || \\    //
//        || || ||\\|| ||_//    //
//     |__|| || || \|| ||       //
//                              //
//                              //
//////////////////////////////////


contract OKCS is ERC1155Creator {
    constructor() ERC1155Creator("ON-KO-CHI-SHIN", "OKCS") {}
}