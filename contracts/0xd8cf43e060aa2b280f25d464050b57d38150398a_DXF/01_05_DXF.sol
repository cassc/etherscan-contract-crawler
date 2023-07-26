// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dreaming in Film
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//    Dreaming In Film is an ongoing collection of 280 unedited captures across the         //
//    planet on 35mm film - my living dream: a journey to all seven continents in 5         //
//    years, including an extensive overland expedition throughout North and South          //
//    America.                                                                              //
//                                                                                          //
//    Film photography has this ethereal quality of capturing memories in way that          //
//    feels present. Textures breathe and dance in the medium. The emotional body,          //
//    the aura, is somehow contained. Each capture develops how memories feel -             //
//    floating, weightless, blurry around the edges. The subconscious, the dream            //
//    state, is conjured in the analog realm.                                               //
//                                                                                          //
//    This collection is intended to explore this relationship between memories and         //
//    dreams, forever converging in the present.                                            //
//                                                                                          //
//    I hope to awaken the viewer's sense of wonder - to create YOUR reality - to           //
//    heed the call to adventure - the Hero's Journey.                                      //
//                                                                                          //
//    I'm building a community along the path for travelers and sovereign individuals.      //
//    For anyone passionate about geoarbitrage. I believe this is the way of the future.    //
//                                                                                          //
//                                                                                          //
//    I hope you'll join me.                                                                //
//                                                                                          //
//                                                                                          //
//    With love,                                                                            //
//    Joe McGrath                                                                           //
//                                                                                          //
//                                                                                          //
//    >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< ><      //
//                                                                                          //
//    - This collection is comprised of true ERC-721 NFTs on a proprietary smart            //
//      contract utilizing manifold.xyz.                                                    //
//                                                                                          //
//    - Holding one of these ERC-721's will grant you privileged access to the              //
//      community and future related global travel brands launched by artist                //
//      Joe McGrath.                                                                        //
//                                                                                          //
//    - All primary collectors will be entitled to a thorough adventure travel              //
//      consulting session with artist Joe McGrath.                                         //
//                                                                                          //
//    - Collectors will be entitled to 50% of ALL commercial licensing royalties            //
//      collected by artist for collector's specific NFT. Artist retains commercial         //
//      rights for all photographs.                                                         //
//                                                                                          //
//    - Each token contains metadata indicating context and rarity.                         //
//                                                                                          //
//    - The majority of NFTs will be in chronological order, though about 10% will          //
//      be flashbacks to earlier touchpoints on the journey. This will be noted in          //
//      the metadata.                                                                       //
//                                                                                          //
//    - A maximum of 280 will be minted. All 1/1's. My very best work.                      //
//                                                                                          //
//    - Estimated completion of this collection is in 2025. My genesis NFT                  //
//      "Sama Sama" was captured in March 2020.                                             //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract DXF is ERC721Creator {
    constructor() ERC721Creator("Dreaming in Film", "DXF") {}
}