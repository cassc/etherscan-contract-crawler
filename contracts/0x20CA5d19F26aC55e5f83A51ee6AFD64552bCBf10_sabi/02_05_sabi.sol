// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: sabi 222
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//                  ___.   .__     //
//      ___________ \_ |__ |__|    //
//     /  ___/\__  \ | __ \|  |    //
//     \___ \  / __ \| \_\ \  |    //
//    /____  >(____  /___  /__|    //
//         \/      \/    \/        //
//                                 //
//                                 //
/////////////////////////////////////


contract sabi is ERC721Creator {
    constructor() ERC721Creator("sabi 222", "sabi") {}
}