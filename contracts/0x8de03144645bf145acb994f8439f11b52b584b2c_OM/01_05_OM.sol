// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ordinary Moments
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//       ____   __  __     //
//      / __ \ |  \/  |    //
//     | |  | || \  / |    //
//     | |  | || |\/| |    //
//     | |__| || |  | |    //
//      \____/ |_|  |_|    //
//                         //
//                         //
//                         //
//                         //
/////////////////////////////


contract OM is ERC721Creator {
    constructor() ERC721Creator("Ordinary Moments", "OM") {}
}