// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BelleShe
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//                                        //
//                                        //
//    .--.      . .     .-. .             //
//    |   )     | |    (   )|             //
//    |--:  .-. | | .-. `-. |--. .-.      //
//    |   )(.-' | |(.-'(   )|  |(.-'      //
//    '--'  `--'`-`-`--'`-' '  `-`--'     //
//                                        //
//                                        //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract MCM is ERC1155Creator {
    constructor() ERC1155Creator("BelleShe", "MCM") {}
}