// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KHIIL EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    888 88P 888 888     888 888 888         //
//    888 8P  888 888     888 888 888         //
//    888 K   8888888     888 888 888         //
//    888 8b  888 888 d8b 888 888 888  ,d     //
//    888 88b 888 888 Y8P 888 888 888,d88     //
//                                            //
//    Creator: KH.iiL                         //
//    https://twitter.com/khrapenkovd         //
//                                            //
//                                            //
////////////////////////////////////////////////


contract KHL is ERC1155Creator {
    constructor() ERC1155Creator("KHIIL EDITIONS", "KHL") {}
}