// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: My mind lost in metaverse
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//    https://opensea.io/assets/ethereum/0x495f947276749ce646f68ac8c248420045cb7b5e/29845678843065965373839376040570629488667162481349706773707395587631879290881/    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Eth is ERC1155Creator {
    constructor() ERC1155Creator("My mind lost in metaverse", "Eth") {}
}