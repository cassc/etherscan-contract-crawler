// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Verified da Vinci - OPEN EDITION
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//              //
//    ┌─┐┌┬┐    //
//    │ ┬│││    //
//    └─┘┴ ┴    //
//              //
//              //
//              //
//////////////////


contract VDVINCI is ERC1155Creator {
    constructor() ERC1155Creator("Verified da Vinci - OPEN EDITION", "VDVINCI") {}
}