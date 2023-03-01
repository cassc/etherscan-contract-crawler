// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GMG Test - Main TOKEN
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//             .AMMMMMMMMMMA.              //
//           .AV. :::.:.:.::MA.            //
//          A' :..        : .:`A           //
//         A'..              . `A.         //
//        A' :.    :::::::::  : :`A        //
//        M  .    :::.:.:.:::  . .M        //
//        M  :   ::.:.....::.:   .M        //
//        V : :.::.:........:.:  :V        //
//       A  A:    ..:...:...:.   A A       //
//      .V  MA:.....:M.::.::. .:AM.M       //
//     A'  .VMMMMMMMMM:.:AMMMMMMMV: A      //
//    :M .  .`VMMMMMMV.:A `VMMMMV .:M:     //
//     V.:.  ..`VMMMV.:AM..`VMV' .: V      //
//      V.  .:. .....:AMMA. . .:. .V       //
//       VMM...: ...:.MMMM.: .: MMV        //
//           `VM: . ..M.:M..:::M'          //
//             `M::. .:.... .::M           //
//              M:.  :. .... ..M           //
//     GMG      V:  M:. M. :M .V           //
//              `V.:M.. M. :M.V'           //
//                                         //
//                                         //
/////////////////////////////////////////////


contract GMGtest is ERC1155Creator {
    constructor() ERC1155Creator("GMG Test - Main TOKEN", "GMGtest") {}
}