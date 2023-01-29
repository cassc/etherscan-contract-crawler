// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cubism x Neo-Perfectionism
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//    CxNP by GLIL    //
//                    //
//                    //
////////////////////////


contract CxNP is ERC1155Creator {
    constructor() ERC1155Creator("Cubism x Neo-Perfectionism", "CxNP") {}
}