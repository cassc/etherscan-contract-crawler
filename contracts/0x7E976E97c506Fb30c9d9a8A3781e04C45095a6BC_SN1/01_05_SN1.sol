// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sachie Nagasawa 1/1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//    ╔═╗┌─┐┌─┐┬ ┬┬┌─┐  ╔╗╔┌─┐┌─┐┌─┐┌─┐┌─┐┬ ┬┌─┐    //
//    ╚═╗├─┤│  ├─┤│├┤   ║║║├─┤│ ┬├─┤└─┐├─┤│││├─┤    //
//    ╚═╝┴ ┴└─┘┴ ┴┴└─┘  ╝╚╝┴ ┴└─┘┴ ┴└─┘┴ ┴└┴┘┴ ┴    //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract SN1 is ERC721Creator {
    constructor() ERC721Creator("Sachie Nagasawa 1/1", "SN1") {}
}