// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Grails  II Mint Pass
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Grails II Mint Pass    //
//                           //
//                           //
///////////////////////////////


contract GIIMP is ERC721Creator {
    constructor() ERC721Creator("Grails  II Mint Pass", "GIIMP") {}
}