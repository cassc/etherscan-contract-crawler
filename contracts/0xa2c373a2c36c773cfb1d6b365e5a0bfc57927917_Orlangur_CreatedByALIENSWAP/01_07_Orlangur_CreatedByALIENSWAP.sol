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



contract Orlangur_CreatedByALIENSWAP is ERC721Creator {
    constructor() ERC721Creator(unicode"Orlangur888", unicode"ORL", 0x694E5C6c5092025644172fE2081188333960fe24, 10, 10, "https://createx.art/api/v1/createx/metadata/ETH/ix9ujnu5hrhtt0c6ccrlr6it47aczsnm/", 
    "https://createx.art/api/v1/createx/collection_url/ETH/ix9ujnu5hrhtt0c6ccrlr6it47aczsnm", 0xA4c150230E8785241f06a6E767aa58e3Ed0E92b8, 1000, 1695954397, 10) {}
}