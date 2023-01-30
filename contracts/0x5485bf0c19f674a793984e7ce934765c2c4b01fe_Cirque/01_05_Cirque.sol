// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cirque
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    🅴🆂🅷🅸🆁🅻🅴🆈🅰🆁🆃    //
//                              //
//                              //
//////////////////////////////////


contract Cirque is ERC721Creator {
    constructor() ERC721Creator("Cirque", "Cirque") {}
}