// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Trans Surf
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//    transurfing 100%    //
//                        //
//                        //
////////////////////////////


contract TRNSRF is ERC1155Creator {
    constructor() ERC1155Creator("Trans Surf", "TRNSRF") {}
}