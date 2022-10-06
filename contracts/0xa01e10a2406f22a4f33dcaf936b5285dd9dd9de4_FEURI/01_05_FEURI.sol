// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fe/urarri
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    ///////FE/URARRI////////    //
//                                //
//                                //
////////////////////////////////////


contract FEURI is ERC721Creator {
    constructor() ERC721Creator("Fe/urarri", "FEURI") {}
}