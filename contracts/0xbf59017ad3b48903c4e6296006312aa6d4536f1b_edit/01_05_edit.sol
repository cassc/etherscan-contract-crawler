// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: editions from the workshop
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    editions.just that. not more.    //
//                                     //
//                                     //
//    more explanation?                //
//                                     //
//                                     //
//    no, just editions.               //
//                                     //
//                                     //
//    everyone can get one, yes.       //
//                                     //
//                                     //
//    no, not forever.                 //
//                                     //
//                                     //
//    yes, artists also need money.    //
//                                     //
//                                     //
//    no, just art.                    //
//                                     //
//                                     //
//    yes, no utility.                 //
//                                     //
//                                     //
//    bye bye.                         //
//                                     //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract edit is ERC1155Creator {
    constructor() ERC1155Creator("editions from the workshop", "edit") {}
}