// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Seizenal mfers
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//     ######  ######## ##    ## ##           //
//    ##    ##      ##  ###   ## ##           //
//    ##           ##   ####  ## ##           //
//     ######     ##    ## ## ## ##           //
//          ##   ##     ##  #### ##           //
//    ##    ##  ##      ##   ### ##           //
//     ######  ######## ##    ## ########     //
//                                            //
//                                            //
////////////////////////////////////////////////


contract SZNL is ERC1155Creator {
    constructor() ERC1155Creator("Seizenal mfers", "SZNL") {}
}