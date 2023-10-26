// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/////////////////////////////////////////////////////////
//  all-in-one NFT generator at https://alienswap.xyz  //
/////////////////////////////////////////////////////////

import "./ERC721Creator.sol";



///////////////////////////////////////////////////
//   ___  _ _                                    //
//  / _ \| (_)                                   //
// / /_\ \ |_  ___ _ __  _____      ____ _ _ __  //
// |  _  | | |/ _ \ '_ \/ __\ \ /\ / / _` | '_ \ //
// | | | | | |  __/ | | \__ \ V  V / (_| | |_) |//
// \_| |_/_|_|\___|_| |_|___/ \_/\_/ \__,_| .__/ //
//                                        | |    //
//                                        |_|    //
///////////////////////////////////////////////////



contract beauty_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"beauty", unicode"beauty", 0x694E5C6c5092025644172fE2081188333960fe24, 1000000, 1000000, "https://createx.art/api/v1/createx/metadata/ETH/xd3zalv07ns0x8z0ct8mdb7g882q1byn/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/xd3zalv07ns0x8z0ct8mdb7g882q1byn", 0x08bc0981c733CF904422FC60aAd8Ee0166E2f7d7, 0, 1697339142, 1000000) {}
}