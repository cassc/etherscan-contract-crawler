// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kyler Steele
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                                      //
//       __ __     __          ______          __       //
//      / //_/_ __/ /__ ____  / __/ /____ ___ / /__     //
//     / ,< / // / / -_) __/ _\ \/ __/ -_) -_) / -_)    //
//    /_/|_|\_, /_/\__/_/   /___/\__/\__/\__/_/\__/     //
//         /___/                                        //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract KS is ERC721Creator {
    constructor() ERC721Creator("Kyler Steele", "KS") {}
}