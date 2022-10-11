// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GM!
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//     __   __       ___           __ ___          //
//    |__) |__) /  \  |   /\  |   |_   |  |__|     //
//    |__) | \  \__/  |  /--\ |__ |__  |  |  |     //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract GM is ERC721Creator {
    constructor() ERC721Creator("GM!", "GM") {}
}