// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AYXO's Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//         **     **    ** **     **   *******      //
//        ****   //**  ** //**   **   **/////**     //
//       **//**   //****   //** **   **     //**    //
//      **  //**   //**     //***   /**      /**    //
//     **********   /**      **/**  /**      /**    //
//    /**//////**   /**     ** //** //**     **     //
//    /**     /**   /**    **   //** //*******      //
//    //      //    //    //     //   ///////       //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract AYXO is ERC1155Creator {
    constructor() ERC1155Creator("AYXO's Editions", "AYXO") {}
}