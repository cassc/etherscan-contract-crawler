// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Domus PFP
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    ________                                   //
//    \______ \   ____   _____  __ __  ______    //
//     |    |  \ /  _ \ /     \|  |  \/  ___/    //
//     |    `   (  <_> )  Y Y  \  |  /\___ \     //
//    /_______  /\____/|__|_|  /____//____  >    //
//            \/             \/           \/     //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract DPFP is ERC1155Creator {
    constructor() ERC1155Creator("Domus PFP", "DPFP") {}
}