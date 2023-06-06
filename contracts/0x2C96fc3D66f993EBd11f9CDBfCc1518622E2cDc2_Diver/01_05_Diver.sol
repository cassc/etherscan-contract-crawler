// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DiviMonster
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//      ////                 //// //////        //
//      //  //             // //  //    //      //
//      //   //          //   //  //     //     //
//      //    //       //     //  //      //    //
//      //     //    //       //  //      //    //
//      //      // //         //  //     //     //
//      //       //           //  ///////       //
//                                              //
//                                              //
//                                              //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract Diver is ERC721Creator {
    constructor() ERC721Creator("DiviMonster", "Diver") {}
}