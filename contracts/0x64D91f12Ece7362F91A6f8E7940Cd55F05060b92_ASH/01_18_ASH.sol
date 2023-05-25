// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

/// @author: manifold.xyz

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//               XX                  XX                 //
//              XXXXXX              XXXXXX              //
//           XXXXXXXXXXXX        XXXXXXXXXXXX           //
//         XXXXXXXXXXXXXXXX    XXXXXXXXXXXXXXXX         //
//        XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX        //
//          XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX          //
//            XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX            //
//               XXXXXXXXXXXXXXXXXXXXXXXX               //
//                XXXXXXXXXXXXXXXXXXXXXX                //
//               XXXXXXXXXXXXXXXXXXXXXXXX               //
//            XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX            //
//          XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX          //
//        XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX        //
//         XXXXXXXXXXXXXXXX    XXXXXXXXXXXXXXXX         //
//           XXXXXXXXXXXX        XXXXXXXXXXXX           //
//              XXXXXX              XXXXXX              //
//                XX                  XX                //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


import "./NFT2ERC20.sol";

contract ASH is NFT2ERC20 {

    constructor() NFT2ERC20("Burn", "ASH") {}

}