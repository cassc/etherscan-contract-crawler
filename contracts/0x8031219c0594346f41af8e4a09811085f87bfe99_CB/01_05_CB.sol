// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cybercity
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                             //
//                                                                                                             //
//    Digital artwork of a cybercity created using DALL-E 2. Specific prompts were used for                    //
//    creating the desired image. Image upscaling done.                                                        //
//                                                                                                             //
//    Retouching was done using Adobe Photoshop.                                                               //
//                                                                                                             //
//    Artwork is featured in Spatialrx gallery by MagicTalents.                                                //
//                                                                                                             //
//    Curation was done by Mark Kelly (Twitter: @saucebook) and Pardis (Twitter: @pardis_world)                //
//                                                                                                             //
//    Gallery name: MagicTalent: Cybercity with AI                                                             //
//                                                                                                             //
//    Link to gallery                                                                                          //
//    https://spatial.io/s/MagicTalent-cybercity-with-AI-62fcac54abce1e00010f7c25?share=4735899166220796494    //
//                                                                                                             //
//    Creator: Pradeep Krishnan (Twitter: @Pradeep_KGR)                                                        //
//                                                                                                             //
//    Image details                                                                                            //
//                                                                                                             //
//    Dimension: 4266 x 4266 pixels                                                                            //
//    Size: 21.5 MB                                                                                            //
//    Resolution: 300 Dpi                                                                                      //
//    Format: PNG                                                                                              //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//    License                                                                                                  //
//    Primary NFT holder is free to use in advertising, and display privately and in groups,                   //
//    including virtual galleries, documentaries, and essays by the holder of the NFT,                         //
//    as long as the creator is credited. Provides no rights to create commercial merchandise,                 //
//    commercial distribution, or derivative works. Copyright remains with creator.                            //
//                                                                                                             //
//                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CB is ERC721Creator {
    constructor() ERC721Creator("Cybercity", "CB") {}
}