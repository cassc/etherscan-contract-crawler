// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Right or Left?
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//                                            //
//                                            //
//      _     __  __    _    ____   ____      //
//     | |__ |  \/  |  / \  / ___| / ___|     //
//     | '_ \| |\/| | / _ \ \___ \| |         //
//     | |_) | |  | |/ ___ \ ___) | |___      //
//     |_.__/|_|  |_/_/   \_\____/ \____|     //
//                                            //
//                                            //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract RL is ERC1155Creator {
    constructor() ERC1155Creator("Right or Left?", "RL") {}
}