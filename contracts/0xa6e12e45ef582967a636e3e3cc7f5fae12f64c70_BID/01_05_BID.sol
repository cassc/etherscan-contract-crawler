// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Breaking it down
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//    <<<<[blink]>>>>>    //
//                        //
//                        //
////////////////////////////


contract BID is ERC1155Creator {
    constructor() ERC1155Creator("Breaking it down", "BID") {}
}