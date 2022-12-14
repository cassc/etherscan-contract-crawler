// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: T3
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    #### ##  ### ###  ### ###   ## ##       //
//    # ## ##   ##  ##   ##  ##  ##   ##      //
//      ##      ##       ##           ##      //
//      ##      ## ##    ## ##      ###       //
//      ##      ##       ##           ##      //
//      ##      ##  ##   ##  ##  ##   ##      //
//     ####    ### ###  ### ###   ## ##       //
//                                            //
//                                            //
////////////////////////////////////////////////


contract T3 is ERC1155Creator {
    constructor() ERC1155Creator("T3", "T3") {}
}