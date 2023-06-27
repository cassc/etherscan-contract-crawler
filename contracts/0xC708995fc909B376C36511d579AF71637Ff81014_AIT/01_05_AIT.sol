// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Art-is-t//ragedy
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//    Art-is-t//ragedy    //
//                        //
//                        //
////////////////////////////


contract AIT is ERC1155Creator {
    constructor() ERC1155Creator("Art-is-t//ragedy", "AIT") {}
}