// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sapphire Ticket NFT 5th
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    .------..------..------..------.    //
//    |A.--. ||N.--. ||T.--. ||E.--. |    //
//    | (\/) || :(): || :/\: || (\/) |    //
//    | :\/: || ()() || (__) || :\/: |    //
//    | '--'A|| '--'N|| '--'T|| '--'E|    //
//    `------'`------'`------'`------'    //
//                                        //
//                                        //
////////////////////////////////////////////


contract ANTE is ERC1155Creator {
    constructor() ERC1155Creator("Sapphire Ticket NFT 5th", "ANTE") {}
}