// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ethereal
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//              .-                                  .     //
//      .---;`-'  /   /                            /      //
//     (   (_)---/---/-.   .-.  ).--..-.  .-.     /       //
//      )--     /   /   |./.-'_/   ./.-'_(  |    /        //
//     (      // _.'    |(__.'/    (__.'  `-'-'_/_.-      //
//     `\___.'                                            //
//                                                        //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract ETHEREAL is ERC721Creator {
    constructor() ERC721Creator("Ethereal", "ETHEREAL") {}
}