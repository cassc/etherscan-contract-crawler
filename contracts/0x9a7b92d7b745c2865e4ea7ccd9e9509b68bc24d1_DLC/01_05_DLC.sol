// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dany.L collection
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//    Short hair Lover    //
//                        //
//                        //
////////////////////////////


contract DLC is ERC1155Creator {
    constructor() ERC1155Creator("Dany.L collection", "DLC") {}
}