// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Primitive RE Abstract
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//                                  //
//      _____  _____                //
//     |  __ \|  __ \     /\        //
//     | |__) | |__) |   /  \       //
//     |  ___/|  _  /   / /\ \      //
//     | |    | | \ \  / ____ \     //
//     |_|    |_|  \_\/_/    \_\    //
//                                  //
//                                  //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract PRA is ERC721Creator {
    constructor() ERC721Creator("Primitive RE Abstract", "PRA") {}
}