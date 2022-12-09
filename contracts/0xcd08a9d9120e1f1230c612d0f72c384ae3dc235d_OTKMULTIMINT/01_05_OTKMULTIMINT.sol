// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OTK MINT, MKIV
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//    OFICINAS TK - Porto, Portugal                                                         //
//    mint facilities #4 - ERC721 Multiples                                                 //
//                                                                                          //
//                                                                                          //
//                                           [email protected]@#( (,%@                                     //
//                                       @@@@@@@@@@@@@@@@@@@&                               //
//                                    %@@@@@@@@@@@@@@@@@@@@@@@                              //
//                                  @@@@@@    /@/     @@@@@@@@@                             //
//                                  @@@@/ (              @@@@@@@,                           //
//                                 &@@@@       &#@@@.     @@@@@@@@                          //
//                                % @@@@.     &@@@@@@@     @@@@@@@,                         //
//                                 @,@@@@     #@@@@@&@     @@@@@@                           //
//                                 *&@@@@@,               &@@@@@@                           //
//                                  (@@@@&@@@,         @@@@@@@@@                            //
//                                      @@@@@@@@@@@@@@/@@@@@@*                              //
//                                        (@@@%@@@&@@@@@@@@&                                //
//                                                                                          //
//                                   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                         //
//                                   @ &@@@@   @%@@@@@@@@@@@@@@@@@@(                        //
//                                              [email protected]@@@          (@@                          //
//                                         @    [email protected]@@    @@@@.                               //
//                                      *@@@@@. [email protected]@@    @@@@@@                              //
//                                    @@@@@@@   @@@@@  @@@@@@@@@@                           //
//                                  *@@@@@@     [email protected]@@@,   @@@@@@@                            //
//                                    @@@@      [email protected]@@(%    @@@@@@@.                          //
//                                    @&          @@/@&      @@@@@@                         //
//                                                    @        @@@                          //
//                                                                                          //
//    @oficinastk                                                                           //
//    https://oficinastk.github.io                                                          //
//                                                                                          //
//    [There is a ten percent (10%) resale royalty embedded in the smart contract, and-     //
//    that Resale Royalty will be paid out of any gross amount you receive when you----     //
//    sell any NFT originating from this contract. If you sell any NFT originating-----     //
//    from this contract on a marketplace or in a manner that does not automatically---     //
//    recognize and send the Resale Royalty to oficinastk.eth for the Artist’s benefit-     //
//     you may be held personally responsible for the amount that should have been paid-    //
//    to oficinastk.eth for the Artist’s benefit upon resale.]-------------------------     //
//    ----------oficinastk.eth - 0xa4aD045d62a493f0ED883b413866448AfB13087C------------     //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract OTKMULTIMINT is ERC721Creator {
    constructor() ERC721Creator("OTK MINT, MKIV", "OTKMULTIMINT") {}
}