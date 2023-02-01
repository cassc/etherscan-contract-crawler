// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: fujiyama
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    fujiyama    //
//                //
//                //
////////////////////


contract fujiyama is ERC1155Creator {
    constructor() ERC1155Creator("fujiyama", "fujiyama") {}
}