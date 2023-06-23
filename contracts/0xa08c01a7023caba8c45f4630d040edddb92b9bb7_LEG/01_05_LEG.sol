// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Little Eating Girls【manifold】
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//      _   _                                         //
//     | \ | |                                        //
//     |  \| |_   _ _ __   __ _ _   _ _   _ _   _     //
//     | . ` | | | | '_ \ / _` | | | | | | | | | |    //
//     | |\  | |_| | | | | (_| | |_| | |_| | |_| |    //
//     |_| \_|\__,_|_| |_|\__, |\__, |\__,_|\__,_|    //
//                         __/ | __/ |                //
//                        |___/ |___/                 //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract LEG is ERC1155Creator {
    constructor() ERC1155Creator(unicode"Little Eating Girls【manifold】", "LEG") {}
}