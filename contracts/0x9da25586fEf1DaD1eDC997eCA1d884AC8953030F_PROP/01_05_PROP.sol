// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PROPAGANDA
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//    The Grid                                                                         //
//    A digital frontier                                                               //
//    I tried to picture clusters of information as they moved through the computer    //
//    What did they look like? Ships? Motorcycles?                                     //
//    Were the circuits like freeways?                                                 //
//    I kept dreaming of a world I thought I'd never see                               //
//    And then, one day                                                                //
//    I got in                                                                         //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract PROP is ERC1155Creator {
    constructor() ERC1155Creator("PROPAGANDA", "PROP") {}
}