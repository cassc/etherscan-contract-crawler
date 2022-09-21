// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: On Rails
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    ┌─┐╔═╗╦╦  ╔╦╗┌─┐┌┬┐┬┬  ┬┌─┐    //
//    ├─┤╠╣ ║║  ║║║├─┤ │ │└┐┌┘│ │    //
//    ┴ ┴╚  ╩╩═╝╩ ╩┴ ┴ ┴ ┴ └┘ └─┘    //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract ORLS is ERC721Creator {
    constructor() ERC721Creator("On Rails", "ORLS") {}
}