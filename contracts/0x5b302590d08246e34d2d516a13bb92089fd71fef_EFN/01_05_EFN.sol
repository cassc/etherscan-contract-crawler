// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Escape From Neighborhood
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    Music Producer based in Istanbul    //
//                                        //
//                                        //
////////////////////////////////////////////


contract EFN is ERC1155Creator {
    constructor() ERC1155Creator("Escape From Neighborhood", "EFN") {}
}