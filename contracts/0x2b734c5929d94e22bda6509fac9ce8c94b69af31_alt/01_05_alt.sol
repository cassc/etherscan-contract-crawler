// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: altgnon
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//            _                                  //
//           | |                                 //
//      __   | | _|_ __    _  _   __   _  _      //
//     /  |  |/   | /  |  / |/ | /  \ / |/ |     //
//    /\_/|_/|__/ |_\_/|//  |  |_\__//  |  |_    //
//                    /|                         //
//                    \|                         //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract alt is ERC721Creator {
    constructor() ERC721Creator("altgnon", "alt") {}
}