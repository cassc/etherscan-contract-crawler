// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @author: https://ethalage.com

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //
//   ___       __   __                     __   __  ___  __        __  ___    __        __   //
//  |__  |    /  \ |__)  /\  |        /\  |__) /__`  |  |__)  /\  /  `  |  | /  \ |\ | /__`  //
//  |    |___ \__/ |  \ /~~\ |___    /~~\ |__) .__/  |  |  \ /~~\ \__,  |  | \__/ | \| .__/  //
//                                                                                           //
//                                  - = E D I T I O N S = -                                  //
//                                                                                           //
// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //

import "./Ethalage1155.sol";

contract FloralAbstractionsEditions is Ethalage1155 {
    constructor() Ethalage1155(LicenseVersion.PERSONAL) {
    }
}