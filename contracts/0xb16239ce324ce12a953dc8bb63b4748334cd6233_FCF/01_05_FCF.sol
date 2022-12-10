// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FREE CLAIM FRIDAYS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    ░█▀▀░█▀▄░█▀▀░█▀▀                //
//    ░█▀▀░█▀▄░█▀▀░█▀▀                //
//    ░▀░░░▀░▀░▀▀▀░▀▀▀                //
//    ░█▀▀░█░░░█▀█░▀█▀░█▄█            //
//    ░█░░░█░░░█▀█░░█░░█░█            //
//    ░▀▀▀░▀▀▀░▀░▀░▀▀▀░▀░▀            //
//    ░█▀▀░█▀▄░▀█▀░█▀▄░█▀█░█░█░█▀▀    //
//    ░█▀▀░█▀▄░░█░░█░█░█▀█░░█░░▀▀█    //
//    ░▀░░░▀░▀░▀▀▀░▀▀░░▀░▀░░▀░░▀▀▀    //
//                                    //
//                                    //
////////////////////////////////////////


contract FCF is ERC1155Creator {
    constructor() ERC1155Creator("FREE CLAIM FRIDAYS", "FCF") {}
}