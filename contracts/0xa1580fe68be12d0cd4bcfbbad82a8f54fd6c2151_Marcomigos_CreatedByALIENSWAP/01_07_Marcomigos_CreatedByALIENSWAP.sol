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



contract Marcomigos_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"Marcomigos", unicode"Marcomigos", 0x694E5C6c5092025644172fE2081188333960fe24, 20, 20, "https://createx.art/api/v1/createx/metadata/ETH/wg0dc6jx1ct21upxy75g55a9ywamda1k/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/wg0dc6jx1ct21upxy75g55a9ywamda1k", 0x7b6961ECFd68F4Ee85036249fBC6AdE5C4B5f41D, 0, 1696770409, 20) {}
}