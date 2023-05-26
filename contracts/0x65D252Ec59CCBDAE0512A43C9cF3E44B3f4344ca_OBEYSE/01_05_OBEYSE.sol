// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OBEY Special Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOO                                                                        OOOO    //
//    OOOO   OOOOO                                                        OOOOO   OOOO    //
//    OOOO  OOOO                                                            OOOO  OOOO    //
//    OOOO  OOOO                                                            OOOO  OOOO    //
//    OOOO  OOOOOOO                                                      OOOOOOO  OOOO    //
//    OOOO  OOOOOOOOOOOOOOOOOOOO                            OOOOOOOOOOOOOOOOOOOO  OOOO    //
//    OOOO  OOOOOOOOOOOOOOOOOOOOOOOOO                  OOOOOOOOOOOOOOOOOOOOOOOOO  OOOO    //
//    OOOO  OOOOOOOOOOOOOOOOOOOOOOOOOOO              OOOOOOOOOOOOOOOOOOOOOOOOOOO  OOOO    //
//    OOOO  OOOOOOOOOOOOOOOOOOOOOOOOOOOO            OOOOOOOOOOOOOOOOOOOOOOOOOOOO  OOOO    //
//    OOOO  OOOOOOOOOOOOOOOOOOOOOOOOOOOOO          OOOOOOOOOOOOOOOOOOOOOOOOOOOOO  OOOO    //
//    BBBB  BBBBBBBBBBB BBBBB   BBBBBBBBBB        BBBBBBBBBB   BBBBB BBBBBBBBBBB  BBBB    //
//    BBBB  BBBBBBBBBB         BBBBBBBBBBB        BBBBBBBBBBB        BBBBBBBBBBB  BBBB    //
//    BBBB  BBBBBBBBBBBBB BBBBBBBBBBBBBBBB        BBBBBBBBBBBBBBBB BBBBBBBBBBBBB  BBBB    //
//    BBBB  BBBBBBBBBB      BBBBBB   BBBBB        BBBBB   BBBBBB      BBBBBBBBBB  BBBB    //
//    BBBB      BBBBB      BBBBB    BBBBB          BBBBB    BBBBB      BBBBB      BBBB    //
//    BBBB              BBBBBB     BBBBB            BBBBB     BBBBBB              BBBB    //
//    BBBB                       BBBBBB              BBBBBB                       BBBB    //
//    BBBB                     BBBBBB                  BBBBBB                     BBBB    //
//    BBBB                    BBBBB                      BBBBB                    BBBB    //
//    BBBB                   BBBBB  BBBBBBB      BBBBBBB  BBBBB                   BBBB    //
//    BBBB                    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB                    BBBB    //
//    BBBB                      BBBBBBB     BBBB     BBBBBBB                      BBBB    //
//    EEEE                                                                        EEEE    //
//    EEEE                EEEE                               EEEEE                EEEE    //
//    EEEE               EEEEEE                              EEEEEE               EEEE    //
//    EEEE              EEEEEEE                              EEEEEEE              EEEE    //
//    EEEE            EEEEE            EEE        EEE            EEEEE            EEEE    //
//    EEEE            EE          EEEEEEEEEEEEEEEEEEEEEEEE          EE            EEEE    //
//    EEEE                   EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE                   EEEE    //
//    EEEE                  EEEEEEEE       EEEEEE       EEEEEEEE                  EEEE    //
//    EEEE  EE                EEEEEEEE                EEEEEEEE                EE  EEEE    //
//    EEEE  EE                    EEEEEEEEE      EEEEEEEE                     EE  EEEE    //
//    EEEE  EEE                         EEEEEEEEEEEE                         EEE  EEEE    //
//    EEEE  EEEE                           EEEEEE                           EEEE  EEEE    //
//    YYYY                                                                        YYYY    //
//    YYYY            YY                                            YY            YYYY    //
//    YYYY            YYYYY                                      YYYYY            YYYY    //
//    YYYY  YYY        YYYYYYYY                              YYYYYYYY        YYY  YYYY    //
//    YYYY  YYYYY       YYYYYYYY                            YYYYYYYY       YYYYY  YYYY    //
//    YYYY  YYYYYYYY   YYYYYYYYYY                          YYYYYYYYYY   YYYYYYYY  YYYY    //
//    YYYY  YYYYYYYYYYYYYYYYYYYYYYYYY                  YYYYYYYYYYYYYYYYYYYYYYYYY  YYYY    //
//    YYYY   YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY   YYYY    //
//    YYYY                                                                        YYYY    //
//    YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY    //
//    YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY    //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract OBEYSE is ERC1155Creator {
    constructor() ERC1155Creator("OBEY Special Editions", "OBEYSE") {}
}