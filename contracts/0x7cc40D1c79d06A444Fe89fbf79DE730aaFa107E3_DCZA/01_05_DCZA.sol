// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Decentralised Collective ZA
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//    ██████╗░░█████╗░░░░░░░███████╗░█████╗░                                        //
//    ██╔══██╗██╔══██╗░░░░░░╚════██║██╔══██╗                                        //
//    ██║░░██║██║░░╚═╝█████╗░░███╔═╝███████║                                        //
//    ██║░░██║██║░░██╗╚════╝██╔══╝░░██╔══██║                                        //
//    ██████╔╝╚█████╔╝░░░░░░███████╗██║░░██║                                        //
//    ╚═════╝░░╚════╝░░░░░░░╚══════╝╚═╝░░╚═╝                                        //
//                                                                                  //
//    Decentralised Collective: South Africa Chapter                                //
//                                                                                  //
//    Leading the charge in decentralised privacy.                                  //
//                                                                                  //
//    Enjoy full privacy protection from seed to smoke, powered by cutting-edge     //
//    decentralised technology.                                                     //
//                                                                                  //
//                                                                                  //
//    Please remember.                                                              //
//                                                                                  //
//    Keep your web3 data safe and secure.                                          //
//                                                                                  //
//    Stay up-to-date with decentralised updates - remember to refresh your         //
//    metadata regularly                                                            //
//                                                                                  //
//    If there are any changes to our procedures you will know in advance           //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////


contract DCZA is ERC721Creator {
    constructor() ERC721Creator("Decentralised Collective ZA", "DCZA") {}
}