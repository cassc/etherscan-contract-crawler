// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Genuine Glitch
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//             .AMMMMMMMMMMA.             //
//           .AV. :::.:.:.::MA.           //
//          A' :..        : .:`A          //
//         A'..              . `A.        //
//        A' :.    :::::::::  : :`A       //
//        M  .    :::.:.:.:::  . .M       //
//        M  :   ::.:.....::.:   .M       //
//        V : :.::.:........:.:  :V       //
//       A  A:    ..:...:...:.   A A      //
//      .V  MA:.....:M.::.::. .:AM.M      //
//     A'  .VMMMMMMMMM:.:AMMMMMMMV: A     //
//    :M .  .`VMMMMMMV.:A `VMMMMV .:M:    //
//     V.:.  ..`VMMMV.:AM..`VMV' .: V     //
//      V.  .:. .....:AMMA. . .:. .V      //
//       VMM...: ...:.MMMM.: .: MMV       //
//           `VM: . ..M.:M..:::M'         //
//             `M::. .:.... .::M          //
//              M:.  :. .... ..M          //
//              V:  M:. M. :M .V          //
//              `V.:M.. M. :M.V'          //
//                                        //
//                                        //
////////////////////////////////////////////


contract Glitch is ERC721Creator {
    constructor() ERC721Creator("Genuine Glitch", "Glitch") {}
}