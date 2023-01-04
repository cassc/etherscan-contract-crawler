// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: fumeiji editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//    ┌─┐┬ ┬┌┬┐┌─┐┬ ┬┬  ┌─┐┌┬┐┬┌┬┐┬┌─┐┌┐┌┌─┐    //
//    ├┤ │ ││││├┤ │ ││  ├┤  │││ │ ││ ││││└─┐    //
//    └  └─┘┴ ┴└─┘┴└┘┴  └─┘─┴┘┴ ┴ ┴└─┘┘└┘└─┘    //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract fumed is ERC721Creator {
    constructor() ERC721Creator("fumeiji editions", "fumed") {}
}