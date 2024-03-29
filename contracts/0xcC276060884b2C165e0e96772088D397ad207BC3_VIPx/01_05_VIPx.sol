// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Very Internet Poster
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                         //
//                                                                                                         //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░           //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░           //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░           //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░           //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░           //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░           //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░▒███████████████████▓▓▓██▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░           //
//    ░░░░░░░░░░░░░░░░░░░░▓▓▓▓▓▓████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░           //
//    ░░░░░░░░░░░░░░░░░▒▒▒████████▓▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░           //
//    ░░░░░░░░░░░░░░░░░█████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░░░░           //
//    ░░░░░░░░░░░░░░░░░█████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██░░░░░░░░░░░░░░░░░           //
//    ░░░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░           //
//    ░░░░░░░░░░░░░░▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██░░░░░░░░░░░░░░           //
//    ░░░░░░░░░░░░░░▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████▓░░░░░░░░░░░           //
//    ░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░▒▓▓░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓░░░░░░░░░░░           //
//    ░░░░░░░░░░░▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▓▓▓▓▓▒▒▒░░░▒▓▓▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▒▒▒░░░░░░░░           //
//    ░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░▓▓▓▓▓▒░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████▓░░░░░░░░           //
//    ░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓░░░▒▓▓▓▓▓▓▓▒░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▓▓██▓▓▓█████▓░░░░░░░░           //
//    ░░░░░░░░░░░▒▓▓▓▓▓░░▒▓▓▓▓▓░░░▒▓▓▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▓▓██▓▓▓█████▓░░░░░░░░           //
//    ░░░░░░░░░░░▒▓▓▓▓▓░░░▓▓▓▓▓▒░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████▓▒▒▒▒▒▓▓▓▓▓▓██▓▓▓▓██▓▓▓██▓▓▓▒░░░░░░░░           //
//    ░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████▒░░░░░░░░█████▓░░▒██▓▓▓██▓░░░░░░░░░░░           //
//    ░░░░░░░░▒▓▓▓▓▓░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░           //
//    ░░░░░░░░▒▓▓▓▓▓▒▒▒▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▓▓▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒░░░░░▓██░░░░░░░░░░░░░░           //
//    ░░░░░░░░▒██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒█████▓░░░░░▓██░░░░░░░░░░░░░░           //
//    ░░░░░░░░▒██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░████████▒░░░░░░░░░░░░░░░░▓██░░░█████▒░░▓██░░░░░░░░░░░░░░           //
//    ░░░░░░░░▒▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒░░░░░░▓▓▓▒▒▒█████▓▓▓░░░░░░░░░░░░░░▒▒▒░░░▒▒▓██▒░░▓██░░░░░░░░░░░░░░           //
//    ░░░░░░░░▒▓▓▓▓▓▓▓▓░░░░░░░░░░░░▒▒▓▓▓░░░▓▓▓█████░░░░░░░░░░░░░░░░░░░░░░▒██▒░░▓██░░░░░░░░░░░░░░           //
//    ░░░░░░░░▒▓▓▓▓▓▓▓▓░░░░░░░░░░░▓██░░░░░░░░▒█████░░░░░░░░░░░░░░▓██░░░█████▒░░▓██░░░░░░░░░░░░░░           //
//    ░░░░░░░░▒▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░▓▓▓░░░▓▓▓█████░░░░░░░░░░░░░░▓██▓▓▓░░▒██▒░░▓██░░░░░░░░░░░░░░           //
//    ░░░░░░░░▒▓▓▓▓▓▓▓▓▒▒▒░░░░░░░░░░░██▓▒▒▓██▓▒▒▓██░░░░░░░░░░░░░░▓▓▓██▓▒▒▒▓▓▒░░▓██░░░░░░░░░░░░░░           //
//    ░░░░░░░░▒▓▓▓▓▓▓▓▓██▓░░░░░░░░░░░████████▒░░▓██░░░░░░░░░░░░░░░░░█████▓░░░░░▓██░░░░░░░░░░░░░░           //
//    ░░░░░░░░▒██▓▓▓▓▓▓█████▒░░░░░░░░░░░████████▒░░░░░░░░░░░░░░░░░░░░░░░░░░░▒█████░░░░░░░░░░░░░░           //
//    ░░░░░░░░░▒▒▓▓▓▓▓▓█████▓▓▓▒░░░░░░░░▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒██▒▒▒░░░░░░░░░░░░░░           //
//    ░░░░░░░░░░░▓██▓▓▓████████▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓██░░░░░░░░░░░░░░░░░           //
//    ░░░░░░░░░░░▓██▓▓▓███████████░░░░░░░░░░░░░░░░░░░░░░▒█████▒░░░░░░░░░░▒█████░░░░░░░░░░░░░░░░░           //
//    ░░░░░░░░░░░▓██▓▓▓▓▓▓████████▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓█████░░░░░░░░░░░░░░░░░           //
//    ░░░░░░░░░░░▒▒▒▓▓▓▓▓▓█████████████▓▒▒▒░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒█████▓▒▒░░░░░░░░░░░░░░░░░           //
//    ░░░░░░░░░░░░░░▓▓▓▓▓▓████████████████▓░░░░░░░░░░░░░░░░░░░░░░▓██████████▒░░░░░░░░░░░░░░░░░░░           //
//    ░░░░░░░░░░░░░░░░░░░░▓▓▓████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█████▒░░░░░░░░░░░░░░░░░░░░░░           //
//    ░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░           //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░           //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░           //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░           //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░           //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░           //
//                                                                                                         //
//                                   Very Internet Person / elle                                           //
//                                                                                                         //
//                                                                                                         //
//                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VIPx is ERC1155Creator {
    constructor() ERC1155Creator("Very Internet Poster", "VIPx") {}
}