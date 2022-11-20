// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Martin Lindenmayer
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//    ##   ##           ####     ######   ##   ##  ##   ##    //
//    ### ###            ##       ##  ##  ### ###  ##   ##    //
//    #######            ##       ##  ##  #######  ##   ##    //
//    ## # ##            ##       ##  ##  ## # ##   #####     //
//    ##   ##            ##       ##  ##  ##   ##     ##      //
//    ##   ##     ##     ##  ##   ##  ##  ##   ##     ##      //
//    ##   ##     ##     ######  ######   ##   ##     ##      //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract MLDMY is ERC721Creator {
    constructor() ERC721Creator("Martin Lindenmayer", "MLDMY") {}
}