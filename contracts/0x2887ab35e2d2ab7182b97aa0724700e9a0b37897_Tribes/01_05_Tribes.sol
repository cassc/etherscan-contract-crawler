// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Two Brides
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//     _____  ___  _  __  ___   __        _____  _   _   __    __  ___  _  __   ___   __      //
//    |_   _|| _ \| ||  \| __|/' _/  __  |_   _|| | | | /__\  |  \| _ \| || _\ | __|/' _/     //
//      | |  | v /| || -<| _| `._`. |__|   | |  | 'V' || \/ | | -<| v /| || v || _| `._`.     //
//      |_|  |_|_\|_||__/|___||___/        |_|  !_/ \_! \__/  |__/|_|_\|_||__/ |___||___/     //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract Tribes is ERC721Creator {
    constructor() ERC721Creator("Two Brides", "Tribes") {}
}