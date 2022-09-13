// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Promethapepe
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//        .----.   @   @    //
//       / .-"-.`.  \v/     //
//       | | '\ \ \_/ )     //
//     ,-\ `-.' /.'  /      //
//    '---`----'----'       //
//                          //
//                          //
//////////////////////////////


contract slug is ERC721Creator {
    constructor() ERC721Creator("Promethapepe", "slug") {}
}