// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PapilionibusAeternis
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    🦋🦋🦋🦋🦋🦋🦋🦋🦋🦋🦋🦋    //
//    🦋🦋🦋🦋🦋🦋🦋🦋🦋🦋🦋🦋    //
//    🦋🦋🦋🦋🦋🦋🦋🦋🦋🦋🦋🦋    //
//    🦋🦋🦋🦋🦋🦋🦋🦋🦋🦋🦋🦋    //
//    🦋🦋🦋🦋🦋🦋🦋🦋🦋🦋🦋🦋    //
//    🦋🦋🦋🦋🦋🦋🦋🦋🦋🦋🦋🦋    //
//    🦋🦋🦋🦋🦋🦋🦋🦋🦋🦋🦋🦋    //
//                                //
//                                //
////////////////////////////////////


contract PA is ERC1155Creator {
    constructor() ERC1155Creator("PapilionibusAeternis", "PA") {}
}