// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Buildship FuelPass
// contract by: buildship.xyz

import "./ERC721Community.sol";

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                                                                           //
//     ______  _     _ _____        ______  _______ _     _ _____  _____     //
//     |_____] |     |   |   |      |     \ |______ |_____|   |   |_____]    //
//     |_____] |_____| __|__ |_____ |_____/ ______| |     | __|__ |          //
//                                                                           //
//     _______ _     _ _______         _____  _______ _______ _______        //
//     |______ |     | |______ |      |_____] |_____| |______ |______        //
//     |       |_____| |______ |_____ |       |     | ______| ______|        //
//                                                                           //
//                                                                           //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////

contract FuelPass is ERC721Community {
    constructor() ERC721Community("Buildship FuelPass", "FUELPASS", 721, 7, START_FROM_ONE, "ipfs://bafybeicmgutmwzftqs2qsr74zmmqhbwdyla3oxtmfibmtosilr5ilf6gou/",
                                  MintConfig(0.3 ether, 2, 2, 0, 0x704C043CeB93bD6cBE570C6A2708c3E1C0310587, false, false, false)) {}
}