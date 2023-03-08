// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rectangle Garden Drive
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    .-----. .-----. .-----. .-----.      //
//    |./*\.| |./*\.| |./*\.| |./*\.|      //
//    |.|R|.| |.|G|.| |.|D|.| |.|R|.|      //
//    |.\*/.| |.\*/.| |.\*/.| |.\*/.|      //
//    '-----' '-----' '-----' '-----'      //
//                                         //
//                                         //
//                                         //
//                                         //
//                                         //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract RGDR is ERC1155Creator {
    constructor() ERC1155Creator("Rectangle Garden Drive", "RGDR") {}
}