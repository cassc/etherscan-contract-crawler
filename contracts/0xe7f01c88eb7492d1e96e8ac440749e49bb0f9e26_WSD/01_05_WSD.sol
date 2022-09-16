// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: w0rlds: special edition
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//                               //
//    ╱╱╱╭━━━╮╱╱╱╱╭┳━╮╱╭━━┳━╮    //
//    ╭┳┳┫╭━╮┣┳┳╮╭╯┃━╋╮┃━━┫┳╯    //
//    ┃┃┃┃┃┃┃┃╭┫╰┫╋┣━┣┫┣━━┃┻╮    //
//    ╰━━┫┃┃┃┣╯╰━┻━┻━┻╯╰━━┻━╯    //
//    ╱╱╱┃╰━╯┃                   //
//                               //
//                               //
///////////////////////////////////


contract WSD is ERC721Creator {
    constructor() ERC721Creator("w0rlds: special edition", "WSD") {}
}