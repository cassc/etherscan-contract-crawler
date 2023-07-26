// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Minted
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//      »»»»       ╓»»»  »»»  »»»       »»» »»»»»»»»»»»»⌐ »»»»»»»»»»» ]»»»»»»»»,                            //
//      ╔░░░╠ç    ≤░░░░  ░░░  ░░░░»     ░░░ ⁿ≈≈≈≈░░░≈≈≈≈⌐ ░░░²²²²²ⁿ┘² «░░╩≈≈≈M╠░░▒╓                         //
//      ╔░░╠░░» ,╠░╠░░░  ░░░  ░░░░░╠ç   ░░░      ░░░      ░░░         :░░[      ╝░░o                        //
//      ╚▒░ `╠░▒▒▒Γ ░░░  ▒▒░  ░░▒ ╚░░▒  ░░▒      ░░░      ░▒▒▒▒▒▒▒▒╠  :░▒▒       ▒▒░                        //
//      ╚▒▒   ╚▒╬   ▒▒▒  ░▒▒  ▒▒▒   ╬▒╬╔▒▒▒      ▒▒▒      ▒▒▒`        :▒▒▒      :▒▒╬                        //
//      ╚▒▒    "    ▒╠╬  ╠╬▒  ▒▒╬    "╬▒╠▒▒      ▒▒╬      ▒▒╠         )▒╬▒  ,,[email protected]╠▒╝                         //
//      ║╬╬         ╬╬╬  ╠╠╬  ╬╬╬      ╚╬╬╠      ╬╬╬      ╬▒▒░▒▒▒░▒▒╬ )╠╠╬╬╬╬╬╬╝╜                           //
//                                                                                                          //
//                            ARTISTS ON THE BLOCKCHAIN                                                     //
//                                                                                                          //
//                                                                                                          //
//    @_Project_Seven, @_r0yart, @_Soulcraft_, @0x_3b, @0xboncuk, @6529er, @abidaker, @agnimax,             //
//    @alistairkeddie, @AnaIsabel_Photo, @Aniltprabhakar, @apocalypticform, @ArmyDad_eth,                   //
//    @art_icu_late, @ArtBanditzNFT, @artNFTlove, @ashikjoh, @ashiq_mk, @aylaelmoussa,                      //
//    @BeautifoolData, @bluejaywayeth, @bombaymalayali, @chrishoiberg, @Crazydoc96, @D_Art2021,             //
//    @dearsoftness, @devendraphotog, @dijaraj, @DomBakerArtist, @ElizaArtPhoto, @FirstLadyNFT,             //
//    @frey, @fuzziemints, @graphitegeorgia, @GregHollandJewl, @GWhittonPhoto, @hariology,                  //
//    @hugofaz, @I_Dreads, @ilovedecay, @itsmesubhash, @jellyfire1, @joshuagalloway, @Kennedybaird_,        //
//    @kitahara_keiko, @korbinian_vogt, @komodaharu, @korbinian_vogt, @lebackpacker, @LegoPunks,            //
//    @lilycallisto, @LimitlessWifey, @littleartphotag, @maneshclicks, @manishmandhyan, @mattdoogue,        //
//    @mintfaced, @mrjonkane, @MSoulwax, @navaneeth_kish, @NFTWannabe, @ObscurePrints, @ompsyram,           //
//    @ovachinsky, @PhotoyogiNFT, @pink0palette, @pixelfactory_, @PrateekSaraf25, @rakesh_pulapa,           //
//    @RealVisionBot, @ricosfilm, @Sacredvoo, @SREERANJ, @sujithks1986, @the_bohomonk, @thinslicephoto,     //
//    @Toadboats, @trent_north_, @TwoBitBears, @UjvalKumar, @ununkx, @WeseeThisnow, @Xose_Casal.            //
//                                                                                                          //
//    Title: Minted                                                                                         //
//    ISBN Hardcover 978-0-473-60817-0                                                                      //
//    ISBN Softcover 978-0-473-60816-3                                                                      //
//    ISBN Kindle 978-0-473-61588-8                                                                         //
//                                                                                                          //
//    © 2022 by MintFace. All rights reserved.                                                              //
//                                                                                                          //
//    Authored by MintFace                                                                                  //
//    Designed and edited by Fredrick Haugen                                                                //
//    Published by UmPrint Publishing                                                                       //
//                                                                                                          //
//    No part of this book may be reproduced in any form or by any electronic or mechanical means,          //
//    including information storage and retrieval systems, without written permission from the author,      //
//    except for the use of brief quotations in a book review.                                              //
//                                                                                                          //
//    Artists retain copyright to works displayed within the Minted book and have confirmed they are        //
//    the copyright owner of the work. Artist provided permission for the Minted book to be sold for        //
//    commercial purposes by MintFace. No other rights have been transferred or forfeited by the artist     //
//    including copyright assertion or trademark protection.                                                //
//                                                                                                          //
//                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MINTED is ERC721Creator {
    constructor() ERC721Creator("Minted", "MINTED") {}
}