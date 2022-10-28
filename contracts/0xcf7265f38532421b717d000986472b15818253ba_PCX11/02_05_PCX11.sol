// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Phantom Clouds
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//     ,_ , ,  _   ,  , ___,_,  , ,     _,,    _, ,  ,  ,_   _,       //
//     |_)|_|,'|\  |\ |' | / \,|\/|    /  |   / \,|  |  | \,(_,       //
//    '| '| |  |-\ |'\|  |'\_/ | `|   '\_'|__'\_/'\__| _|_/  _)       //
//     '  ' `  '  `'  `  ' '   '  `      `  ' '      `'     '         //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract PCX11 is ERC721Creator {
    constructor() ERC721Creator("Phantom Clouds", "PCX11") {}
}