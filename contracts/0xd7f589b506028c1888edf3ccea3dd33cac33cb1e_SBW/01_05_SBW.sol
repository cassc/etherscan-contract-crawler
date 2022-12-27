// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shamlu B&W
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//                                                       //
//          '||                        '||`              //
//           ||                         ||               //
//    (''''  ||''|,  '''|.  '||),,(|,   ||  '||  ||`     //
//     `'')  ||  || .|''||   || || ||   ||   ||  ||      //
//    `...' .||  || `|..||. .||    ||. .||.  `|..'|.     //
//                                                       //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract SBW is ERC721Creator {
    constructor() ERC721Creator("Shamlu B&W", "SBW") {}
}