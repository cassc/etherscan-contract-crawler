// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jan Sladecko
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//                                                                                    //
//    .d88888b  oo dP dP              a88888b.          dP                            //
//    88.    "'    88 88             d8'   `88          88                            //
//    `Y88888b. dP 88 88 dP    dP    88        dP    dP 88d888b. .d8888b. .d8888b.    //
//          `8b 88 88 88 88    88    88        88    88 88'  `88 88ooood8 Y8ooooo.    //
//    d8'   .8P 88 88 88 88.  .88    Y8.   .88 88.  .88 88.  .88 88.  ...       88    //
//     Y88888P  dP dP dP `8888P88     Y88888P' `88888P' 88Y8888' `88888P' `88888P'    //
//                            .88                                                     //
//                        d8888P                                                      //
//                                                                                    //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////


contract SLADE is ERC721Creator {
    constructor() ERC721Creator("Jan Sladecko", "SLADE") {}
}