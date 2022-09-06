// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Phantasmagoria
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    ┌─┐┬ ┬┌─┐┌┐┌┌┬┐┌─┐┌─┐┌┬┐┌─┐┌─┐┌─┐┬─┐┬┌─┐    //
//    ├─┘├─┤├─┤│││ │ ├─┤└─┐│││├─┤│ ┬│ │├┬┘│├─┤    //
//    ┴  ┴ ┴┴ ┴┘└┘ ┴ ┴ ┴└─┘┴ ┴┴ ┴└─┘└─┘┴└─┴┴ ┴    //
//    DevaMotion                                  //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract PHA is ERC721Creator {
    constructor() ERC721Creator("Phantasmagoria", "PHA") {}
}