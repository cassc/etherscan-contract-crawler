// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Femicide
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                          //
//                                                                                                                                          //
//    No one understands the motive of these perpetrators better than the women and girls who are no longer alive to tell their stories.    //
//    (Iran Revolution 2023)                                                                                                                //
//    Woman/Life/Freedom                                                                                                                    //
//                                                                                                                                          //
//                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FEMI is ERC721Creator {
    constructor() ERC721Creator("Femicide", "FEMI") {}
}