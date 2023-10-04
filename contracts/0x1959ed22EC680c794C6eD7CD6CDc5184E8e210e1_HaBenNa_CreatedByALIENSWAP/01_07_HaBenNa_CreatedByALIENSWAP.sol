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



contract HaBenNa_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"HaBenNa", unicode"HBA", 0x694E5C6c5092025644172fE2081188333960fe24, 1000, 1000, "https://createx.art/api/v1/createx/metadata/ETH/krm1bqt1s2vk279ov8z5ye170sc5mn2q/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/krm1bqt1s2vk279ov8z5ye170sc5mn2q", 0xBc2E7d827C788005ba971599D7F7DC911673a6F5, 1000, 1695556534, 1000) {}
}