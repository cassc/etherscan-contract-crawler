// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: UGLY MONSTER ft. Grimes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//                           //
//                _          //
//      _  _ __ _| |_  _     //
//     | || / _` | | || |    //
//      \_,_\__, |_|\_, |    //
//          |___/   |__/     //
//                           //
//                           //
//                           //
///////////////////////////////


contract UGLY is ERC721Creator {
    constructor() ERC721Creator("UGLY MONSTER ft. Grimes", "UGLY") {}
}