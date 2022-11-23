// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: isatest
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    /////////////////    //
//    //             //    //
//    //             //    //
//    //    isamu    //    //
//    //             //    //
//    //             //    //
//    /////////////////    //
//                         //
//                         //
/////////////////////////////


contract IST is ERC721Creator {
    constructor() ERC721Creator("isatest", "IST") {}
}