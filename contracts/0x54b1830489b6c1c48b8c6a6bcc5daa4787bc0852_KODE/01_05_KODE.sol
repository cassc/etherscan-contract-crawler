// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KODE by KVLT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    ░█▄▀░▄▀▄░█▀▄▒██▀    //
//    ░█▒█░▀▄▀▒█▄▀░█▄▄    //
//    ░█▄▀░▄▀▄░█▀▄▒██▀    //
//    ░█▒█░▀▄▀▒█▄▀░█▄▄    //
//    ░█▄▀░▄▀▄░█▀▄▒██▀    //
//    ░█▒█░▀▄▀▒█▄▀░█▄▄    //
//                        //
//                        //
////////////////////////////


contract KODE is ERC721Creator {
    constructor() ERC721Creator("KODE by KVLT", "KODE") {}
}