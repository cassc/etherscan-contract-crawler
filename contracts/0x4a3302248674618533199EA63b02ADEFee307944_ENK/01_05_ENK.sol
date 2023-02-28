// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ENK
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//                            //
//     _____ _   _  _   __    //
//    |  ___| \ | || | / /    //
//    | |__ |  \| || |/ /     //
//    |  __|| . ` ||    \     //
//    | |___| |\  || |\  \    //
//    \____/\_| \_/\_| \_/    //
//                            //
//                            //
//                            //
//                            //
//                            //
////////////////////////////////


contract ENK is ERC1155Creator {
    constructor() ERC1155Creator("ENK", "ENK") {}
}