// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AP 4599
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//      __   ____     ___   ___  ___   ___      //
//     / _\ (  _ \   / _ \ / __)/ _ \ / _ \     //
//    /    \ ) __/  (__  ((___ \\__  )\__  )    //
//    \_/\_/(__)      (__/(____/(___/ (___/     //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract AP4599 is ERC721Creator {
    constructor() ERC721Creator("AP 4599", "AP4599") {}
}