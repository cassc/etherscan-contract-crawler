// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A Tesssttt
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    Just here to do a lil testyy    //
//                                    //
//                                    //
////////////////////////////////////////


contract atst is ERC1155Creator {
    constructor() ERC1155Creator("A Tesssttt", "atst") {}
}