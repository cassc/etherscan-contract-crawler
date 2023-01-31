// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: I Heart Pepe
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    Non Fungible Nat    //
//                        //
//                        //
////////////////////////////


contract HEARTPEPE is ERC721Creator {
    constructor() ERC721Creator("I Heart Pepe", "HEARTPEPE") {}
}