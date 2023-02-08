// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks - OnTable
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    (╯°□°)╯︵ ┻━┻    //
//                    //
//                    //
////////////////////////


contract OnTable is ERC721Creator {
    constructor() ERC721Creator("Checks - OnTable", "OnTable") {}
}