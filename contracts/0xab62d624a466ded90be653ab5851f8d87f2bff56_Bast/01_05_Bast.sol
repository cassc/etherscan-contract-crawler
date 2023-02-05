// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bastille
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                            //
//                                                                                                                                            //
//    Modernity is the transitory, the fugitive, the contingent, the half of art, the other half of which is the eternal and the immutable    //
//                                                                                                                                            //
//                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Bast is ERC721Creator {
    constructor() ERC721Creator("Bastille", "Bast") {}
}