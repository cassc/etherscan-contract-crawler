// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: sirQL8R
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    sirQL8R by Tennessee Loveless    //
//                                     //
//                                     //
/////////////////////////////////////////


contract sirQL8R is ERC1155Creator {
    constructor() ERC1155Creator("sirQL8R", "sirQL8R") {}
}