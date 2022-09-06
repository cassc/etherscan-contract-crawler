// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: marto bearer tokens
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    ʕ •ᴥ•ʔ                  ʕ •ᴥ•ʔ    //
//                                      //
//    ʕ　-ᴥ•ʔ  ︻デ═一 ▸       ʕ •ᴥ•ʔ       //
//                                      //
//    ʕ •ᴥ•ʔ                            //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract mbeat is ERC721Creator {
    constructor() ERC721Creator("marto bearer tokens", "mbeat") {}
}