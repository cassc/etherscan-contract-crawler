// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Balloon Nyan
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//     By Arachnyx    //
//                    //
//                    //
////////////////////////


contract BALNYAN is ERC1155Creator {
    constructor() ERC1155Creator("Balloon Nyan", "BALNYAN") {}
}