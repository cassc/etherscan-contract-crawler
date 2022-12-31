// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Trenchloot Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//                  |   |=|          .---.         |=|   |    //
//                  |===|o|=========/     \========|o|===|    //
//                  |   | |         \() ()/        | |   |    //
//                  |===|o|======{'-.) A (.-'}=====|o|===|    //
//                  | __/ \__     '-.\uuu/.-'    __/ \__ |    //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract TRNCH is ERC721Creator {
    constructor() ERC721Creator("Trenchloot Editions", "TRNCH") {}
}