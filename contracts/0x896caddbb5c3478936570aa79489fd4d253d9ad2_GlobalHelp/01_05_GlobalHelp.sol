// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Earthquake
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                                                           //
//    Magnitude 7.8 and 7.5 earthquakes have hit southern Tukey. Thousands of people are affected and in need of our help. All mint income and subsequent royalties will be sent to the official charity. It is an individual social responsibility project created after the earthquake.    //
//                                                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GlobalHelp is ERC1155Creator {
    constructor() ERC1155Creator("Earthquake", "GlobalHelp") {}
}