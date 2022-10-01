// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SELF AWARE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//     ______     ______     __     __           //
//    /\  ___\   /\  __ \   /\ \  _ \ \          //
//    \ \___  \  \ \  __ \  \ \ \/ ".\ \         //
//     \/\_____\  \ \_\ \_\  \ \__/".~\_\        //
//      \/_____/   \/_/\/_/   \/_/   \/_/        //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract SAW is ERC721Creator {
    constructor() ERC721Creator("SELF AWARE", "SAW") {}
}