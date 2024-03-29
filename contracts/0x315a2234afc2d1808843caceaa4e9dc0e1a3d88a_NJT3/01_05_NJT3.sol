// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NJ_Tony_2023
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                          //
//                                                                                                          //
//     ****     **      **       **********                                   ****   ****   ****   ****     //
//    /**/**   /**     /**      /////**///                     **   **       */// * *///** */// * */// *    //
//    /**//**  /**     /**          /**      ******  *******  //** **       /    /*/*  */*/    /*/    /*    //
//    /** //** /**     /**          /**     **////**//**///**  //***           *** /* * /*   ***    ***     //
//    /**  //**/**     /**          /**    /**   /** /**  /**   /**           *//  /**  /*  *//    /// *    //
//    /**   //**** **  /**          /**    /**   /** /**  /**   **           *     /*   /* *      *   /*    //
//    /**    //***//*****  *****    /**    //******  ***  /**  **      *****/******/ **** /******/ ****     //
//    //      ///  /////  /////     //      //////  ///   //  //      ///// //////  ////  //////  ////      //
//                                                                                                          //
//                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NJT3 is ERC721Creator {
    constructor() ERC721Creator("NJ_Tony_2023", "NJT3") {}
}