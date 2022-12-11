// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mukul Kapoor
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//       _____         __         .__        //
//      /     \  __ __|  | ____ __|  |       //
//     /  \ /  \|  |  \  |/ /  |  \  |       //
//    /    Y    \  |  /    <|  |  /  |__     //
//    \____|__  /____/|__|_ \____/|____/     //
//            \/           \/                //
//                                           //
//                                           //
///////////////////////////////////////////////


contract MKEDS is ERC1155Creator {
    constructor() ERC1155Creator("Mukul Kapoor", "MKEDS") {}
}