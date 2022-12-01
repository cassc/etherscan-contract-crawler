// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rizwan Shah
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    rizart.eth    //
//                  //
//                  //
//////////////////////


contract Rizart is ERC721Creator {
    constructor() ERC721Creator("Rizwan Shah", "Rizart") {}
}