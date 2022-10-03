// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Crypto Testament
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    In the beginning...                   //
//    And                                   //
//    In the end, Saint Exodus saved us.    //
//                                          //
//                                          //
//////////////////////////////////////////////


contract CRX is ERC721Creator {
    constructor() ERC721Creator("Crypto Testament", "CRX") {}
}