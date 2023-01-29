// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SALVAGE OUR PEPE MEME
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                        //
//                                                                                                                                        //
//    The original design is "Destroy This Mad Brute – Enlist"                                                                            //
//    This is a North American propaganda poster of Harry Ryle Hopps produced in 1917, as part of the Committee on Public Information.    //
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SOPM is ERC721Creator {
    constructor() ERC721Creator("SALVAGE OUR PEPE MEME", "SOPM") {}
}