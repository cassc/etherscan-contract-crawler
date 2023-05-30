// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jason Matias Fine Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//              JJJJJJJJJJJMMMMMMMM               MMMMMMMMFFFFFFFFFFFFFFFFFFFFFF      AAA                                  //
//              J:::::::::JM:::::::M             M:::::::MF::::::::::::::::::::F     A:::A                                 //
//              J:::::::::JM::::::::M           M::::::::MF::::::::::::::::::::F    A:::::A                                //
//              JJ:::::::JJM:::::::::M         M:::::::::MFF::::::FFFFFFFFF::::F   A:::::::A                               //
//                J:::::J  M::::::::::M       M::::::::::M  F:::::F       FFFFFF  A:::::::::A                              //
//                J:::::J  M:::::::::::M     M:::::::::::M  F:::::F              A:::::A:::::A                             //
//                J:::::J  M:::::::M::::M   M::::M:::::::M  F::::::FFFFFFFFFF   A:::::A A:::::A                            //
//                J:::::j  M::::::M M::::M M::::M M::::::M  F:::::::::::::::F  A:::::A   A:::::A                           //
//                J:::::J  M::::::M  M::::M::::M  M::::::M  F:::::::::::::::F A:::::A     A:::::A                          //
//    JJJJJJJ     J:::::J  M::::::M   M:::::::M   M::::::M  F::::::FFFFFFFFFFA:::::AAAAAAAAA:::::A                         //
//    J:::::J     J:::::J  M::::::M    M:::::M    M::::::M  F:::::F         A:::::::::::::::::::::A                        //
//    J::::::J   J::::::J  M::::::M     MMMMM     M::::::M  F:::::F        A:::::AAAAAAAAAAAAA:::::A                       //
//    J:::::::JJJ:::::::J  M::::::M               M::::::MFF:::::::FF     A:::::A             A:::::A                      //
//     JJ:::::::::::::JJ   M::::::M               M::::::MF::::::::FF    A:::::A               A:::::A                     //
//       JJ:::::::::JJ     M::::::M               M::::::MF::::::::FF   A:::::A                 A:::::A                    //
//         JJJJJJJJJ       MMMMMMMM               MMMMMMMMFFFFFFFFFFF  AAAAAAA                   AAAAAAA                   //
//                                                                                                                         //
//                                                                                                                         //
//    JASON MATIAS FINE ART                                                                                                //
//    www.jasonmatias.com                                                                                                  //
//    [email protected]                                                                                                //
//    _________                                                                                                            //
//                                                                                                                         //
//    This NFT represents the exclusive license to display the attached asset. The license terms are as follows:           //
//                                                                                                                         //
//    :: Display Rights ::                                                                                                 //
//                                                                                                                         //
//    The NFT owner is permitted to display this artwork privately and in groups with fewer than 100 participants,         //
//    including virtual galleries, documentaries, and essays created by individuals holding the NFT.                       //
//                                                                                                                         //
//    :: Commercial Usage ::                                                                                               //
//                                                                                                                         //
//    This NFT does not grant the owner the right to create commercial merchandise, engage in commercial distribution,     //
//    or produce derivative works based on the artwork.                                                                    //
//                                                                                                                         //
//    :: Commercial License ::                                                                                             //
//                                                                                                                         //
//    For any commercial usage of the artwork, a separate commercial license must be obtained. Please contact the          //
//    artist via email to discuss and negotiate the terms of such a license.                                               //
//                                                                                                                         //
//    :: Artist's Rights ::                                                                                                //
//                                                                                                                         //
//    The artist retains all rights to the artwork, including but not limited to intellectual property rights,             //
//    reproduction rights, and distribution rights.                                                                        //
//                                                                                                                         //
//    :: Requests and Permissions ::                                                                                       //
//                                                                                                                         //
//    If you require further clarification or permission regarding the use of the artwork, please reach out to             //
//    the artist via email.                                                                                                //
//                                                                                                                         //
//    :: Sales Policy ::                                                                                                   //
//                                                                                                                         //
//    All sales of this NFT are final, and no refunds or exchanges will be provided.                                       //
//    Please note that this license applies only to the specific NFT and artwork described herein and does not             //
//    extend to any other works by the artist.                                                                             //
//                                                                                                                         //
//    ---------                                                                                                            //
//                                                                                                                         //
//    A Note From The Artist                                                                                               //
//                                                                                                                         //
//    Each piece I create is a labor of love, a product of both my heart and mind, carefully crafted until it              //
//    reaches a point where I believe it's ready to be shared with the world. That you recognize the value in              //
//    my art, support me through ownership, and join my community by possessing this token of my                           //
//    creativity means more to me than words can express. Your appreciation and involvement in my artistic                 //
//    journey is truly the world to me.                                                                                    //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JMFA is ERC721Creator {
    constructor() ERC721Creator("Jason Matias Fine Art", "JMFA") {}
}