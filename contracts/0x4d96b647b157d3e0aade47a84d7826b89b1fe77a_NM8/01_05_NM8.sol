// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NIGHTMARE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//     _   _ __  __  ___      //
//    | \ | |  \/  |/ _ \     //
//    |  \| | \  / | (_) |    //
//    | . ` | |\/| |> _ <     //
//    | |\  | |  | | (_) |    //
//    |_| \_|_|  |_|\___/     //
//                            //
//                            //
//                            //
////////////////////////////////


contract NM8 is ERC1155Creator {
    constructor() ERC1155Creator("NIGHTMARE", "NM8") {}
}