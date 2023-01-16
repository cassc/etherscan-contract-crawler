// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: aFILMativo Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//     ┌─┐╔═╗╦╦  ╔╦╗┌─┐┌┬┐┬┬  ┬┌─┐    //
//     ├─┤╠╣ ║║  ║║║├─┤ │ │└┐┌┘│ │    //
//     ┴ ┴╚  ╩╩═╝╩ ╩┴ ┴ ┴ ┴ └┘ └─┘    //
//                                    //
//                                    //
////////////////////////////////////////


contract aFEd is ERC1155Creator {
    constructor() ERC1155Creator("aFILMativo Editions", "aFEd") {}
}