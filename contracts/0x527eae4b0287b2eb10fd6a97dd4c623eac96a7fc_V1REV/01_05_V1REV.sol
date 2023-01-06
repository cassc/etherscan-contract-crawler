// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TheRev.eth
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////
//                                                                             //
//                                                                             //
//                                                                             //
//    888888 88  88 888888 88""Yb 888888 Yb    dP     888888 888888 88  88     //
//      88   88  88 88__   88__dP 88__    Yb  dP      88__     88   88  88     //
//      88   888888 88""   88"Yb  88""     YbdP   .o. 88""     88   888888     //
//      88   88  88 888888 88  Yb 888888    YP    `"' 888888   88   88  88     //
//                                                                             //
//                                                                             //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////


contract V1REV is ERC721Creator {
    constructor() ERC721Creator("TheRev.eth", "V1REV") {}
}