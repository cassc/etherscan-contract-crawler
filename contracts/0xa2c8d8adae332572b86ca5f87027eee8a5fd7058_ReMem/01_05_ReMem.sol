// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ReMeme Lab by BiggieSmols
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//                                                        //
//                                                        //
//     _____     _____                  __        _       //
//    | __  |___|     |___ _____ ___   |  |   ___| |_     //
//    |    -| -_| | | | -_|     | -_|  |  |__| .'| . |    //
//    |__|__|___|_|_|_|___|_|_|_|___|  |_____|__,|___|    //
//                                                        //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract ReMem is ERC1155Creator {
    constructor() ERC1155Creator("ReMeme Lab by BiggieSmols", "ReMem") {}
}