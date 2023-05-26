// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PENGU23
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//                            __          //
//                         -=(o '.        //
//                            '.-.\       //
//                            /|  \\      //
//                            '|  ||      //
//                  noot       _\_):,_    //
//                                        //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract PENGU is ERC721Creator {
    constructor() ERC721Creator("PENGU23", "PENGU") {}
}