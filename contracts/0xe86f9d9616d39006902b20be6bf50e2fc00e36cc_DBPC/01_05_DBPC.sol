// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Concepts
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    ****Working title****        //
//                                 //
//    I'm writing a show.          //
//                                 //
//    And animating it.            //
//                                 //
//    And voicing it.              //
//                                 //
//    Welcome to the beginning.    //
//                                 //
//                                 //
/////////////////////////////////////


contract DBPC is ERC1155Creator {
    constructor() ERC1155Creator("The Concepts", "DBPC") {}
}