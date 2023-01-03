// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: pizzacat
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    ┌─┐┬┌─┐┌─┐┌─┐┌─┐┌─┐┌┬┐    //
//    ├─┘│┌─┘┌─┘├─┤│  ├─┤ │     //
//    ┴  ┴└─┘└─┘┴ ┴└─┘┴ ┴ ┴     //
//                              //
//                              //
//////////////////////////////////


contract pizzacat is ERC721Creator {
    constructor() ERC721Creator("pizzacat", "pizzacat") {}
}