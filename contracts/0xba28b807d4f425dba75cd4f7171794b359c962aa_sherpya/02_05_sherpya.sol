// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: sherpya
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    ┌─┐┬ ┬┌─┐┬─┐┌─┐┬ ┬┌─┐    //
//    └─┐├─┤├┤ ├┬┘├─┘└┬┘├─┤    //
//    └─┘┴ ┴└─┘┴└─┴   ┴ ┴ ┴    //
//                             //
//                             //
/////////////////////////////////


contract sherpya is ERC721Creator {
    constructor() ERC721Creator("sherpya", "sherpya") {}
}