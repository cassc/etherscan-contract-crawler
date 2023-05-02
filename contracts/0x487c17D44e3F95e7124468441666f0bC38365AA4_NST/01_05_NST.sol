// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nest
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//     _______                   __       //
//     \      \   ____   _______/  |_     //
//     /   |   \_/ __ \ /  ___/\   __\    //
//    /    |    \  ___/ \___ \  |  |      //
//    \____|__  /\___  >____  > |__|      //
//            \/     \/     \/            //
//                                        //
//                                        //
//                                        //
//                                        //
//                                        //
//                                        //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract NST is ERC1155Creator {
    constructor() ERC1155Creator("Nest", "NST") {}
}