// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TRASHy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//      ___/-\___     ___/-\___     ___/-\___     //
//     |---------|   |---------|   |---------|    //
//      |       |     | | | | |     |   |   |     //
//      |       |     | | | | |     | | | | |     //
//      |       |     | | | | |     | | | | |     //
//      | | | | |     | | | | |     | | | | |     //
//      |_______|     |_______|     |_______|     //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract TRASHy is ERC721Creator {
    constructor() ERC721Creator("TRASHy", "TRASHy") {}
}