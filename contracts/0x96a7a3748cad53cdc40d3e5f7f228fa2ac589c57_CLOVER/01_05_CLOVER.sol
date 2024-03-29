// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: COLLECTOR COLLIDER
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                        //
//                                                                                                        //
//                                                                                                        //
//                                ▄▄▄▄██████▄                                                             //
//                                ████████████▄ ‧̍̊          ,▄▄▄▄‧̍̊˙· 𓆝.° ｡                            //
//                          ,▄▄▄▄██████████████▌‧̍̊˙· 𓆝.° ｡˚████████‧̍̊˙· 𓆝.° ｡˚𓆛˚｡ °.                 //
//                         ████████████████████▌        ▐█████████‧̍̊˙· 𓆝.° ｡˚𓆛˚｡ °.𓆞                  //
//                         ▀███████████████████▌ ‧̍̊˙· 𓆝 ▄████████████▄▄▄▄‧̍̊˙· 𓆝.° ｡˚𓆛˚｡ °.𓆞 ·       //
//                           ███████████████████    ▄████████████████████‧̍̊˙· 𓆝.° ｡˚𓆛˚｡ °.𓆞 ·˙‧̍̊     //
//                            `▀████████████████‧̍   ███████████████████████‧̍̊                           //
//                              ,▄▄▄▄▄▄ ▀▀███████▄████████████████████████▌‧̍̊˙· 𓆝.° ｡˚𓆛                //
//                          ▄██████████████████████████‧̍̊‧̍̊▀▀`▀▀▀▀████████████                          //
//                         ▐█████████████████████████████████▄▄▄ ▀▀█████▀‧̍̊˙· 𓆝.°                       //
//                         ╙█████████████████ █▌ ██████████████████▄ `‧̍̊˙· 𓆝.° ｡˚𓆛˚                    //
//                           ▀▀████████████▀  ▐█ ‧̍ ████████████████████‧̍̊˙· 𓆝.° ｡˚𓆛˚｡ °.              //
//                              █████████▀    ▐█‧̍̊˙·████████████████████▄‧̍̊˙· 𓆝.° ｡˚𓆛˚｡ °.𓆞          //
//                               ███████▌     █‧̍̊˙·  █████████████████████‧̍̊                            //
//                                ▀█████      █‧̍̊˙· 𓆝████████████████████▀‧̍̊˙· 𓆝.° ｡˚𓆛˚｡ °.𓆞 ·˙     //
//                                  ▀▀▀      ▐█‧̍̊˙· 𓆝.██████████████▀▀▀‧̍̊˙· 𓆝.° ｡˚𓆛˚｡ °.𓆞 ·˙‧̍̊`    //
//                                           █‧̍̊▌‧̍̊˙· 𓆝. ████████████‧̍̊˙· 𓆝.° ｡˚𓆛˚｡ °.𓆞 ·˙‧̍̊      //
//                                           ██‧̍̊˙· 𓆝.° ｡▀█████████▌‧̍̊˙· 𓆝.° ｡˚𓆛                     //
//                                           ██‧̍̊˙· 𓆝.° ｡˚▀███████‧̍̊˙· 𓆝.° ｡                          //
//                                           ▐█▌‧̍̊˙· 𓆝.° ｡˚𓆛`▀▀▀▀                                      //
//                                            █▌‧̍̊˚𓆛˚                                                   //
//                                            ██▄‧̍̊˙· 𓆝.° ｡˚𓆛                                          //
//                                            ▐██‧̍̊˙· 𓆝.° ｡˚                                            //
//                                            ▐██▌‧̍̊˙· 𓆝.°                                              //
//                                            ████‧̍̊˙· 𓆝.° ｡˚𓆛˚｡ °.                                    //
//                                            ████‧̍̊˙· 𓆝.° ｡˚𓆛˚｡ °.𓆞 ·˙                               //
//                                            ▀▀‧̍̊˙· 𓆝.° ｡˚𓆛˚｡                                         //
//                                                                                                        //
//                                            ,▄▄,‧̍̊˙· 𓆝.°                                              //
//                                         ▄███████‧̍̊˙· 𓆝.° ｡˚𓆛˚｡ °.𓆞                                 //
//                                        █████████▌‧̍̊˙· 𓆝.° ｡˚𓆛˚｡ °                                   //
//                                        ▀███████▀‧̍̊˙· 𓆝.° ｡˚                                          //
//                                                                                                        //
//                                                                                                        //
//                      __       _      ___ ___ __   _  __  __  ___ ___                                   //
//                      )_) )   /_) )\ ) )   )  ) ) /_) ) ) ) )  )   )                                    //
//                     /   (__ / / (  ( (   (  /_/ / / /_/ /_/ _(_ _(_                                    //
//                                                                                                        //
//                                                                                                        //
//                                                                                                        //
//                                                                                                        //
//                                                                                                        //
//                                                                                                        //
//                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CLOVER is ERC721Creator {
    constructor() ERC721Creator("COLLECTOR COLLIDER", "CLOVER") {}
}