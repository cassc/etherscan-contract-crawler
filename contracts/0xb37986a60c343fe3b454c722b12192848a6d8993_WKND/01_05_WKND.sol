// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: yung wknd editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    it's the wknd    //
//     (editions)      //
//                     //
//                     //
/////////////////////////


contract WKND is ERC1155Creator {
    constructor() ERC1155Creator("yung wknd editions", "WKND") {}
}