// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Sundays x Oveck
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////
//             //
//             //
//    Oveck    //
//             //
//             //
/////////////////


contract TSDS is ERC1155Creator {
    constructor() ERC1155Creator("The Sundays x Oveck", "TSDS") {}
}