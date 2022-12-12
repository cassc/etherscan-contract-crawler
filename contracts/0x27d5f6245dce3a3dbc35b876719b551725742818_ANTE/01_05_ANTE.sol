// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vesta Ticket NFT[Sapphire 5th benefit]
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
    constructor() ERC1155Creator("Vesta Ticket NFT[Sapphire 5th benefit]", "ANTE") {}
}