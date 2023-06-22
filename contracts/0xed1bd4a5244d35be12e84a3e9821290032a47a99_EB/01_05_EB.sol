// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ethernal Butterfly
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//    🦋🦋🦋🦋🦋🦋🦋🦋🦋🦋    //
//    🦋🦋🦋🦋🦋🦋🦋🦋🦋🦋    //
//    🦋🦋🦋🦋🦋🦋🦋🦋🦋🦋    //
//    🦋🦋🦋🦋🦋🦋🦋🦋🦋🦋    //
//                            //
//                            //
////////////////////////////////


contract EB is ERC1155Creator {
    constructor() ERC1155Creator("Ethernal Butterfly", "EB") {}
}