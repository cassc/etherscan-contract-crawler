// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GIOVINATOR
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    G G   GIOVINATOR   GIOVINATOR   GIOVINATOR   GIOVINATOR   █▀▀▀▀▀▀▀▀▀▀▀█   GIOVINATOR   G G    //
//    I I   GIOVINATOR   GIOVINATOR   GIOVINATOR   GIOVINATOR   █           █   GIOVINATOR   I I    //
//    O O █▀▀▀▀▀▀▀▀▀▀▀█▀▀▀█▀▀▀▀▀▀▀█▀▀▀▀█▀▀▀▀█▀▀▀█▀▀▀▀▀▀▀█▀▀▀█▀▀▀▀▀▀▀█   █▀▀▀▀▀▀▀█▀▀▀▀▀▀▀▀█   O O    //
//    V V █           █   █       █    █    █   █       █   █   ▄   █   █       █    ▄   █   V V    //
//    I I █   █▀▀▀▀▀▀▀█   █   █   █    █    █   █   █   █   █   █   █   █   █   █    █   █   I I    //
//    N N █   █▄▄▄▄   █   █   █   █    ▀    █   █   █   █   █       █   █   █   █      ▄▄█   N N    //
//    A A █           █   █       █         █   █   █       █   █   █   █       █    █   █   A A    //
//    T T █▄▄▄▄▄▄▄▄▄▄▄█▄▄▄█▄▄▄▄▄▄▄█▀▀█▄▄▄█▀▀█▄▄▄█▄▄▄█▄▄▄▄▄▄▄█▄▄▄█▄▄▄█▄▄▄█▄▄▄▄▄▄▄█▄▄▄▄█▄▄▄█   T T    //
//    O O   GIOVINATOR   GIOVINATOR   GIOVINATOR   GIOVINATOR   GIOVINATOR      GIOVINATOR   O O    //
//    R R   GIOVINATOR   GIOVINATOR   GIOVINATOR   GIOVINATOR   GIOVINATOR      GIOVINATOR   R R    //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract BRICK is ERC721Creator {
    constructor() ERC721Creator("GIOVINATOR", "BRICK") {}
}