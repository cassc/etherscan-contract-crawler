// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Docile Delinquent
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//     ____  ____  __    __  __ _   __   _  _  ____  __ _  ____     //
//    (    \(  __)(  )  (  )(  ( \ /  \ / )( \(  __)(  ( \(_  _)    //
//     ) D ( ) _) / (_/\ )( /    /(  O )) \/ ( ) _) /    /  )(      //
//    (____/(____)\____/(__)\_)__) \__\)\____/(____)\_)__) (__)     //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract ETH is ERC721Creator {
    constructor() ERC721Creator("The Docile Delinquent", "ETH") {}
}