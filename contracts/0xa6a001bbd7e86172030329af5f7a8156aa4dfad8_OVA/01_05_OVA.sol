// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OVASELFSKY by OVACHINSKY
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//                       _____ ______ _      ______   _              //
//                      / ____|  ____| |    |  ____| | |             //
//       _____   ____ _| (___ | |__  | |    | |__ ___| | ___   _     //
//      / _ \ \ / / _` |\___ \|  __| | |    |  __/ __| |/ / | | |    //
//     | (_) \ V / (_| |____) | |____| |____| |  \__ \   <| |_| |    //
//      \___/ \_/ \__,_|_____/|______|______|_|  |___/_|\_\\__, |    //
//                                                          __/ |    //
//                                                         |___/     //
//             OVACHINSKY x RIK OOSTENBROEK x SELF x 2022            //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract OVA is ERC721Creator {
    constructor() ERC721Creator("OVASELFSKY by OVACHINSKY", "OVA") {}
}