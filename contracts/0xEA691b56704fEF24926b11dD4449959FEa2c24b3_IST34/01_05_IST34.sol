// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: UMAGUMAG
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    UMAGUMAG    //
//                //
//                //
////////////////////


contract IST34 is ERC1155Creator {
    constructor() ERC1155Creator("UMAGUMAG", "IST34") {}
}