// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ETH Hapoochis
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//                                                     //
//      _   _                              _     _     //
//     | | | | __ _ _ __   ___   ___   ___| |__ (_)    //
//     | |_| |/ _` | '_ \ / _ \ / _ \ / __| '_ \| |    //
//     |  _  | (_| | |_) | (_) | (_) | (__| | | | |    //
//     |_| |_|\__,_| .__/ \___/ \___/ \___|_| |_|_|    //
//                 |_|                                 //
//                                                     //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract HCH is ERC721Creator {
    constructor() ERC721Creator("ETH Hapoochis", "HCH") {}
}