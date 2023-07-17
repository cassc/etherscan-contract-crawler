// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Summertime
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    a1111ac011d0    //
//                    //
//                    //
////////////////////////


contract Summertime is ERC721Creator {
    constructor() ERC721Creator("Summertime", "Summertime") {}
}