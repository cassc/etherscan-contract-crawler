// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Relic Reserve Token
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                                                                      //
//    ___   ___         ___   ___         ___   ___   ___   ___   ___         ___       //
//    |   | |     |       |   |           |   | |     |     |     |   | |  /  |         //
//    |-+-  |-+-  |       +   |           |-+-  |-+-   -+-  |-+-  |-+-  | +   |-+-      //
//    |  \  |     |       |   |           |  \  |         | |     |  \  |/    |         //
//           ---   ---   ---   ---               ---   ---   ---               ---      //
//                                                                                      //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////


contract RESERVE is ERC1155Creator {
    constructor() ERC1155Creator("Relic Reserve Token", "RESERVE") {}
}