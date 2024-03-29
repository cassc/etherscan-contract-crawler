// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ShambambykliEditions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//    ███████ ██   ██  █████  ███    ███ ██████   █████  ███    ███ ██████  ██    ██ ██   ██ ██      ██     ███████ ██████  ██ ████████ ██  ██████  ███    ██ ███████     //
//    ██      ██   ██ ██   ██ ████  ████ ██   ██ ██   ██ ████  ████ ██   ██  ██  ██  ██  ██  ██      ██     ██      ██   ██ ██    ██    ██ ██    ██ ████   ██ ██          //
//    ███████ ███████ ███████ ██ ████ ██ ██████  ███████ ██ ████ ██ ██████    ████   █████   ██      ██     █████   ██   ██ ██    ██    ██ ██    ██ ██ ██  ██ ███████     //
//         ██ ██   ██ ██   ██ ██  ██  ██ ██   ██ ██   ██ ██  ██  ██ ██   ██    ██    ██  ██  ██      ██     ██      ██   ██ ██    ██    ██ ██    ██ ██  ██ ██      ██     //
//    ███████ ██   ██ ██   ██ ██      ██ ██████  ██   ██ ██      ██ ██████     ██    ██   ██ ███████ ██     ███████ ██████  ██    ██    ██  ██████  ██   ████ ███████     //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ShE is ERC1155Creator {
    constructor() ERC1155Creator("ShambambykliEditions", "ShE") {}
}