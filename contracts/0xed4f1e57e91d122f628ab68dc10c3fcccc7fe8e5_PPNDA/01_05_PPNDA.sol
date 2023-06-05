// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pixel Pandas
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    .----. .----. .-. .-..----.   .--.      //
//    | {}  }| {}  }|  `| || {}  \ / {} \     //
//    | .--' | .--' | |\  ||     //  /\  \    //
//    `-'    `-'    `-' `-'`----' `-'  `-'    //
//                                            //
//                                            //
////////////////////////////////////////////////


contract PPNDA is ERC1155Creator {
    constructor() ERC1155Creator("Pixel Pandas", "PPNDA") {}
}