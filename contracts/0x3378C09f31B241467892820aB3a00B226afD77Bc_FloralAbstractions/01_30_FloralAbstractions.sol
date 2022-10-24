// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @author: https://ethalage.com

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //
//   ___       __   __                     __   __  ___  __        __  ___    __        __   //
//  |__  |    /  \ |__)  /\  |        /\  |__) /__`  |  |__)  /\  /  `  |  | /  \ |\ | /__`  //
//  |    |___ \__/ |  \ /~~\ |___    /~~\ |__) .__/  |  |  \ /~~\ \__,  |  | \__/ | \| .__/  //
//                                                                                           //
// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //

import "./Ethalage.sol";

contract FloralAbstractions is Ethalage {
    constructor() Ethalage("Floral Abstractions", "FA", LicenseVersion.COMMERCIAL) {
        setArtist("https://www.instagram.com/florintintin/");
        setContractURI("https://ethalage.com/contracts/fa.json");
        _setBaseTokenURI("ipfs://bafybeibbxxqaie4oi7hz5nl6hte6widvklnv2tqum4ru3aene7oilpn6cm/");
    }
}