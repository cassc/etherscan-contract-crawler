// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Drawbot CT2
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//    ░█▀▄░█▀▄░█▀▀░▀█▀░▀▀▄    //
//    ░█░█░█▀▄░█░░░░█░░▄▀░    //
//    ░▀▀░░▀▀░░▀▀▀░░▀░░▀▀▀    //
//                            //
//                            //
////////////////////////////////


contract DBCT2 is ERC1155Creator {
    constructor() ERC1155Creator("Drawbot CT2", "DBCT2") {}
}