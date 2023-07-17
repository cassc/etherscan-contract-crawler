// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DoGa-Records
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//    © 2023 DoGa Records.  All rights reserved.     //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract DGREC is ERC1155Creator {
    constructor() ERC1155Creator("DoGa-Records", "DGREC") {}
}