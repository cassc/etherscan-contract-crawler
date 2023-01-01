// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bart Slaby Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//     ____   __   ____  ____    ____  ____     //
//    (  _ \ / _\ (  _ \(_  _)  (  __)/ ___)    //
//     ) _ (/    \ )   /  )(     ) _) \___ \    //
//    (____/\_/\_/(__\_) (__)   (____)(____/    //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract ME is ERC1155Creator {
    constructor() ERC1155Creator("Bart Slaby Editions", "ME") {}
}