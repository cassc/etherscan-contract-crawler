// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: T.I.Boine
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//     ____   ____ _____ _   _ ______     //
//    |  _ \ / __ \_   _| \ | |  ____|    //
//    | |_) | |  | || | |  \| | |__       //
//    |  _ <| |  | || | | . ` |  __|      //
//    | |_) | |__| || |_| |\  | |____     //
//    |____/ \____/_____|_| \_|______|    //
//                                        //
//                                        //
////////////////////////////////////////////


contract Boine is ERC721Creator {
    constructor() ERC721Creator("T.I.Boine", "Boine") {}
}