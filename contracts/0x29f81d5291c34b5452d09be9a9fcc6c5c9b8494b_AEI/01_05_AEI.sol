// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Akigashi event illustration
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//                            //
//    ╔═╗┬┌─┬┌─┐┌─┐┌─┐┬ ┬┬    //
//    ╠═╣├┴┐││ ┬├─┤└─┐├─┤│    //
//    ╩ ╩┴ ┴┴└─┘┴ ┴└─┘┴ ┴┴    //
//                            //
//                            //
//                            //
////////////////////////////////


contract AEI is ERC1155Creator {
    constructor() ERC1155Creator("Akigashi event illustration", "AEI") {}
}