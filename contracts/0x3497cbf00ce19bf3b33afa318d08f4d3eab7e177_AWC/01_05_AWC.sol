// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Argentina World Champion
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                   .BBBBQBBBBr   2BBBBBB      rBBBQBBP     ZBBBBBBBB jBBQQ1.   BBBBBBBBBB:SBBBQBBBQBvYBBBB BBBBBBB 7BBBB      BBBBBBQ.                        //
//                    .sBBBBBBBQ:   :BBBY       iBBBBQBB      iBBQBBBB  iBBQBBB   5BBBBBBB   iBQBBBQB. UBBB. BBQBBBB  BBBQ      BBBBBBBq                        //
//                      .BQBBBBBQ:   .B5         BBBQBBBi      BBBBBBB   dQBBBBB  .BQBQBBB    BBQBQBQ  5BB   BBBBBBB   QBB      .BBBQBBB                        //
//                        BQBBBBBB:   BY       Q rBBBBBBB      BBBBBBB   ZBBBBBQ: .BBBBQBB    BBBBBBB  dBq   QBBBBBB.  .BB    .B BBBBBBBr                       //
//                      B  BBBQBBBB.  B2      .Bv BBBBBBQ      BBBQBQB   DBBBBBB: .BQBBBBB    BBBBBBB  .2    BBBBBBB.   ur    MB vBBBBBBB                       //
//                      BQ .BBBBBBBB  BK      BB  BBBBBQBq     BBBBQBB   dBQBQBB  :QBBBBBB    BBBBBQB        BBBBQBB.         BB  BBBQBBB                       //
//                      BB  :BBBBBBBB :P      BR  :BBBBBBB     BBBBBBB  .BBBBBQ   :BBBBBBB QBBQBBBBBB        BBBBBBB.        qQ.  QBBBBBBP                      //
//                      BB   :BQBBBBBB       DB    BBQBBBB7    BBQBBBB vBBBBq.    :QBBBBBB    BBBBBBB        BBBBBBB.        BB   .QBBBBBB                      //
//                      BB    :BBBBBBBB.     BM rr.BBBBBBBB    BBBQBBB            :BBBBBBB    BBBBBBB        BBBBBBB.       jB .riiBQBBBBBr                     //
//                      BB     :BBBBBBB2    KB :BBBBBBBBBBB    QBQBQBB            :BBQBBBB    BBBBBBB        BBBBBBQ.       BB BBBBBBBBQBBB                     //
//                      BB      :BBBBBBs    BB      gBBBBBBb   BBBBBBB            .BBBBBBB    BBBBBBB        BBBBBQB       vB.      QBBBQBB                     //
//                     EBBE      iBBBBBj  iBBB      EBBBBBBB. :BBBBQBBr           UBBQBBBQ   rBBBBBBB:      :BBBBBBBs     uQBu      BBBBBBBB                    //
//                   .BBBBBB.     rBQBBJ BBBBBBX   RBBBBBBQBBBBBBBBBQBQB         BBBBBBBBBB:5BBBQBBBBBP    BBBBBQBQBQB. .BBBBBB.  .BBBBBBBQBB.                  //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AWC is ERC721Creator {
    constructor() ERC721Creator("Argentina World Champion", "AWC") {}
}