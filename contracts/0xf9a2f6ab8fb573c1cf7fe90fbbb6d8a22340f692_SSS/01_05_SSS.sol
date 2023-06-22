// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Saint - Holy Card
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//    ░█▀▀░█▀█░▀█▀░█▀█░▀█▀    //
//    ░▀▀█░█▀█░░█░░█░█░░█░    //
//    ░▀▀▀░▀░▀░▀▀▀░▀░▀░░▀░    //
//                            //
//                            //
////////////////////////////////


contract SSS is ERC1155Creator {
    constructor() ERC1155Creator("Saint - Holy Card", "SSS") {}
}