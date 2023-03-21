// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MFERS ALL IN
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//              _____                          //
//             |M .  | _____                   //
//             | /.\ ||F ^  | _____            //
//             |(_._)|| / \ ||E _  | _____     //
//             |  |  || \ / || ( ) ||R_ _ |    //
//             |____V||  .  ||(_'_)||( v )|    //
//                    |____V||  |  || \ / |    //
//                           |____V||  .  |    //
//                                  |____V|    //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract MFALLIN is ERC1155Creator {
    constructor() ERC1155Creator("MFERS ALL IN", "MFALLIN") {}
}