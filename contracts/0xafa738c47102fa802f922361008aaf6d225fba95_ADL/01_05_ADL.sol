// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Paintings
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//      _  _        //
//     /_// | /     //
//    / //_.'/_,    //
//                  //
//                  //
//////////////////////


contract ADL is ERC721Creator {
    constructor() ERC721Creator("Paintings", "ADL") {}
}