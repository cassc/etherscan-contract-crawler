// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Free Pepper-Mint-Tea
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    The Free Pepper-Mint-Tea    //
//                                //
//                                //
////////////////////////////////////


contract TFPMT is ERC1155Creator {
    constructor() ERC1155Creator("The Free Pepper-Mint-Tea", "TFPMT") {}
}