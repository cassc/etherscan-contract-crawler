// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: H2BH
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//    ┌∩┐(◣_◢)┌∩┐                                        //
//                                                       //
//    ARTISTS COMING TOGETHER TO BENEFIT UKRAINE 2023    //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract H2BH is ERC721Creator {
    constructor() ERC721Creator("H2BH", "H2BH") {}
}