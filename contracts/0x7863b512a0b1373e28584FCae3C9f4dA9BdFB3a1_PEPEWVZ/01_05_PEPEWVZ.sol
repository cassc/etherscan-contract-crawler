// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PepeWavez
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//    Hurric4n3Ike    //
//                    //
//                    //
////////////////////////


contract PEPEWVZ is ERC1155Creator {
    constructor() ERC1155Creator("PepeWavez", "PEPEWVZ") {}
}