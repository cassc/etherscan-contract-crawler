// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Liminality
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                         //
//                                                                                                         //
//    IIIAAIIIIAAAIIIIAAIIIIIAAIIIIAAAIIIIAAIIIIIAAIIIIAAAAIIIIAAIIIIIAAIIIIAAAIIIIAAIIIIIAAIIIIAAAIIII    //
//    IIIIIIAAIIIIIIAIIIIIIIIIIIAAIIIIIAAIIIIIIIIIIIIIIIIIIIIAIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIAI    //
//    AAIIIIAAIIIIIAAIIIIIAIIIIIAAIIIIAa...iIAAAIIIIAAIIIIIIAAIIIIAa...iIAAIIIIIAAIIIIAAAIIIIAAIIIIIAAI    //
//    IIIAAIIIIAAAIIIIAAIIIIAAAIIIAAI.       .aIAIAAIIIIAAAAIIIIIA.      .iaAAIAIIIIAAIIIIIAAIIIIAAAIII    //
//    IIIIIIIIIIIIIIIIIIIIIIIIIAai.             .aaIIIIIIIIIIAi.            .iaaIIIIIIIIIIIIIIIIIIIIIII    //
//    AAIIIIAAIIIIIAAIIIIAAAIAii.                 .aAAIIIIIAi.                 .daIIIIAAAIIIIAAAIIIIAAI    //
//    IIIAIIIIIIAIIIIIAAIIIIAd.                     .0IIIAA.                     .AIAIIIIIAAIIIIIAIIIII    //
//    IIIAAIIIIIAIIIIIAAIIIai.                       .AaAi.                       .AIIIIIIAAIIIIIAIIIII    //
//    AAIIIIAAIIIIIAAIIIIAIA.                         .,.                          .aIAAAIIIIAAIIIIIAAI    //
//    IIIIIIIIIIIIIIIIIIIIA.                           .                            .IIIIIIIIIIIIIIIIII    //
//    IIIAAIIIIAAAIIIIAAIIa.                                                        .AIIIIAAIIIIAAAIIII    //
//    AAIIIIAAIIIIIAAIIIIAA.                                                        .IIAAIIIIAAIIIIIAAI    //
//    AIIIIIAAIIIIIAAIIIIAI.                       MINDSCAPE                        .IIAAIIIIAAIIIIIAAI    //
//    IIIAAIIIIAAAIIIIAAIII0.                                                      .AIIIIIAAIIIIAAAIIII    //
//    IIIIIIIIIIIIIIIIIIIIIIa.                        AI                          .iIIIIIIIIIIIIIIIIIII    //
//    AAIIIIAAAIIIIAAIIIIAAAAa.                                                  .aAIIAAAIIIIAAIIIIAAAI    //
//    IIIAAIIIIIAIIIIIAAIIIIIaa.                                                .dAAAIIIIIAIIIIIIAIIIII    //
//    IIIAAIIIIIAIIIIIAAIIIIIAaa.                                              .aAIIAIIIIIAAIIIIIAIIIII    //
//    AAIIIIAAIIIIIAAIIIIAAAIIIAd.                                            .iIAIIIIAAAIIIIAAIIIIIAAI    //
//    IIIIIIIIIIIIIIIIIIIIIIIIIIAA.                                          .0IIIIIIIIIIIIIIIIIIIIIIII    //
//    AIIAAIIIIAAAIIIIAAIIIIAAAIIAAi.                                      .dAAIIIIAAIIIIIAAIIIIAAAIIII    //
//    IAIIIIAAIIIIIAAIIIIIAIIIIIIIIAa.                                    .0AIIIAAIIIIIAAIIIIAAIIIIIAAI    //
//    IIIIIIIIIIIIIAAIIIIIAIIIIIAIIIIAa.                                .dAIIIIIAIIIIIIIIIIIIIAIIIIIAAI    //
//    AIIAAIIIIAAAIIIIAAIIIIIAAIIIIAAAAia.                             .AIIIAAAIIIIAAIIIIIAAIIIIAAAIIII    //
//    IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIAA.                          .iAIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII    //
//    IAIIIIAAIIIIIAAIIIIAAAIIIIAAIIIIIAAIAi.                      .iAIIIAAIIIIIAAIIIIAAAIIIIAAIIIIAAAI    //
//    AIIAAIIIIIAIIIIIAAIIIIIAAIIIIAAIIIIIAIAi.                  .aaIIAAIIIIAAIIIIIAAIIIIIAAIIIIIAIIIII    //
//    AIIAAIIIIIAIIIIIIAIIIIIAIIIIIIIIIIIIAIIIAi.              .daIIIIAAIIIIIAIIIIIAAIIIIIAAIIIIIAIIIII    //
//    IAIIIIAAIIIIIAAIIIIAAAIIIIAAIIIIIAAIIIIAAIAa.          .dAIIAAAIIIIAAIIIIIAAIIIIAAAIIIIAAIIIIIAAI    //
//    IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIAi.      .daIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII    //
//    AIIAAIIIIAAAIIIIAAIIIIIAAIIIIAAAIIIIAAIIIIIAAIAa. .idaIIIAAIIIIIAAIIIIAAAIIIIAAIIIIIAAIIIIAAAIIII    //
//    IAIIIIAAIIIIIAAIIIIIAAIIIIAAIIIIIAAIIIIAAIIIIIAIA.AIIIAAIIIIAAAIIIIAAIIIIIAAIIIIAAAIIIIAAIIIIIAAI    //
//    IIIIIIAAIIIIIAAIIIIIAIIIIIIAIIIIIAAIIIIIAAIIIIIAIIIIIIAAIIIIIAIIIIIIAIIIIIAIIIIIIAIIIIIIAIIIIIAAI    //
//    AAIAAIIIIAAAIIIIAAIIIIIAAIIIIAAAIIIIAAIIIIIAAIIIIAAAAIIIIAAIIIIIAAIIIIAAAIIIIAAIIIIIAAIIIIAAAIIII    //
//                                                                                                         //
//                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MSAI is ERC721Creator {
    constructor() ERC721Creator("Liminality", "MSAI") {}
}