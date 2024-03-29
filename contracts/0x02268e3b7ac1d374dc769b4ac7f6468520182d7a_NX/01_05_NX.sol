// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OPEN EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                ▄▌                                        //
//                                               ▓███                                       //
//                                              ██████                                      //
//                                            ,████████,                                    //
//                                           ▄████▀ ████▄                                   //
//                                          ▓████▀   █████                                  //
//                                         █████      ╙████                                 //
//                                       ,█████   ██,  ╙████                                //
//                                      ╓████▀  ,████▄   ████▄                              //
//                                     ▄████▀  ▄███████   ████▌                             //
//                                    █████   ▓█████████   ▀████                            //
//                                  ,█████   ████████████   ╙████                           //
//                                 ╓████▀  ,██████████████▄   ████▄                         //
//                                ▄████▀  ╓████████████████▌   ████▌                        //
//                               █████   ▄███████████████████   ▀████                       //
//                              █████   ██████████████████████   ╙████                      //
//                            ╓█████  ,████████████████████████▄   ████▄                    //
//                           ▄████▀  ╓██████████████████████████▌   ████▌                   //
//                          ▓████   ▄█████████████████████████████   ▀████                  //
//                         █████   ████████████████████████████████   ╙████                 //
//                       ┌█████   ██████████████████████████████████▄  ╙████µ               //
//                      ▄████▀  ╓████████████████████████████████████▌   ████▌              //
//                     ▓████▀  ▄███████████████████████████████████████   █████             //
//                    █████   ▓█████████████████████████████████████████   ╙████            //
//                  ,█████   ████████████████████████████████████████████µ  ╙████,          //
//                 ▄████▀  ┌██████████████████████████████████████████████▌   ████▄         //
//                ▓████▀  ▄█████████████████████████████████████████████████   █████        //
//               █████   ▓███████████████████████████████████████████████████   ▀████       //
//             ,█████                                                            ╙████      //
//            ╓████████████████████████████████████████████████████████████████████████▄    //
//           '╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙    //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract NX is ERC1155Creator {
    constructor() ERC1155Creator("OPEN EDITIONS", "NX") {}
}