// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Nereids
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//                                                             //
//      _____ _            _   _               _     _         //
//     |_   _| |__   ___  | \ | | ___ _ __ ___(_) __| |___     //
//       | | | '_ \ / _ \ |  \| |/ _ \ '__/ _ \ |/ _` / __|    //
//       | | | | | |  __/ | |\  |  __/ | |  __/ | (_| \__ \    //
//       |_| |_| |_|\___| |_| \_|\___|_|  \___|_|\__,_|___/    //
//                                                             //
//                                                             //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract NEREIDS is ERC721Creator {
    constructor() ERC721Creator("The Nereids", "NEREIDS") {}
}