// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SURGICAL NIGHTMARES
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//      __      _   __ ___  _                ___  __    ___           _   _  __     //
//     (_  | | |_) /__  |  /   /\  |    |\ |  |  /__ |_| | |\/|  /\  |_) |_ (_      //
//     __) |_| | \ \_| _|_ \_ /--\ |_   | \| _|_ \_| | | | |  | /--\ | \ |_ __)     //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////


contract SURNIM is ERC721Creator {
    constructor() ERC721Creator("SURGICAL NIGHTMARES", "SURNIM") {}
}