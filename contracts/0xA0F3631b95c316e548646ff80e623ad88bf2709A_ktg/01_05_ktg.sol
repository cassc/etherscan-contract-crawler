// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: kthegroove
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//    _  _ ___ _  _ ____ ____ ____ ____ ____ _  _ ____     //
//    |_/   |  |__| |___ | __ |__/ |  | |  | |  | |___     //
//    | \_  |  |  | |___ |__] |  \ |__| |__|  \/  |___     //
//                                                         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract ktg is ERC721Creator {
    constructor() ERC721Creator("kthegroove", "ktg") {}
}