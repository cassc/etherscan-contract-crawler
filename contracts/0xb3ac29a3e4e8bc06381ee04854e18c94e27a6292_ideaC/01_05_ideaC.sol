// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ideartist x culture
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//    ideartist x culture     //
//                            //
//                            //
////////////////////////////////


contract ideaC is ERC1155Creator {
    constructor() ERC1155Creator("ideartist x culture", "ideaC") {}
}