// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Diamonds - MM Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                              //
//                                                                                              //
//                                                                                              //
//      ******** **      **                        ******          **         **        **      //
//     **////// /**     //                        /*////**        //   ***** /**       /**      //
//    /**       /**      ** *******   *****       /*   /**  ****** ** **///**/**      ******    //
//    /*********/****** /**//**///** **///**      /******  //**//*/**/**  /**/****** ///**/     //
//    ////////**/**///**/** /**  /**/*******      /*//// ** /** / /**//******/**///**  /**      //
//           /**/**  /**/** /**  /**/**////       /*    /** /**   /** /////**/**  /**  /**      //
//     ******** /**  /**/** ***  /**//******      /******* /***   /**  ***** /**  /**  //**     //
//    ////////  //   // // ///   //  //////       ///////  ///    //  /////  //   //    //      //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////


contract DMME is ERC721Creator {
    constructor() ERC721Creator("Diamonds - MM Edition", "DMME") {}
}