// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MUKHLIS's Art Journey 1on1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//               ____   _____            _     __     ____     //
//         /\   |  _ \ / ____|          | |   /_ |   / /_ |    //
//        /  \  | |_) | (___   __ _ _ __| |_   | |  / / | |    //
//       / /\ \ |  _ < \___ \ / _` | '__| __|  | | / /  | |    //
//      / ____ \| |_) |____) | (_| | |  | |_   | |/ /   | |    //
//     /_/    \_\____/|_____/ \__,_|_|   \__|  |_/_/    |_|    //
//                                                             //
//                                                             //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract ABSart1ON1 is ERC721Creator {
    constructor() ERC721Creator("MUKHLIS's Art Journey 1on1", "ABSart1ON1") {}
}