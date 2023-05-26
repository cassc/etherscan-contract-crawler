// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: POETRY CARDS VOL 1 | META/VERSE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                    `..`                                                    //
//                                             `:oy.  ommo  .yo/`                                             //
//                                          `  ymNm.  sNNo  -NNm/  -`                                         //
//                                       :oho  hNNm.  sNNo  -NNN/ `mds:`                                      //
//                                   .  :mNNo  hNNm.  sNNo  -NNN/ `mNNm- `.                                   //
//                                -+hd` :NNNo  hNNm.  sNNo  -NNN/ `mNNN- /dho:                                //
//                             ` `mNNm` :NNNo  hNNm.  sNNo  -NNN/ `mNNN- /mNNm` .`                            //
//                        `.-+y/ `NNNm` :NNNo  hNNm.  sNNo  -NNN/ `mNNN- /mNNN` oho-.                         //
//                     `` /mmNN+ `NNNm` :NNNo  hNNm.  sNNo  -NNN/ `mNNN- /mNNN` oNNmh- ..                     //
//                  ./sd- +NNNN+ `NNNm` :NNNo  hNNm.  sNNo  -NNN/ `mNNN- /mNNN` oNNNm: sdy+.                  //
//              ``  dNNN- +NNNN+ `NNNm` :NNNo  hNNm.  sNNo  -NNN/ `mNNN- /mNNN` oNNNm: sNNNh  ``              //
//            .oh+  mNNN- +NNNN+ `NNNm` :NNNo  hNNm.  sNNo  -NNN/ `mNNN- /mNNN` oNNNm: sNNNh  +ds-            //
//           +mNN+  mNNN- +NNNN+ `NNNm` :NNNo  hNNm.  sNNo  -NNN/ `mNNN- /mNNN` oNNNm: sNNNh  +NNm:           //
//           hNNN+  mNNN- +NNNN+ `NNNm` :NNNo  hNNm.  odd+  -NNN/ `mNNN- /mNNN` oNNNm: sNNNh  +NNN/           //
//        :  hNNN+  mNNN- +NNNN+ `NNNm` :NNNo  hNNm.   ``   -NNN/ `mNNN- /mNNN` oNNNm: sNNNh  +NNN/  o        //
//       :d  hNNN+  mNNN- +NNNN+ `NNNm` :NNNo  hNNmo////////oNNN/ `mNNN- /mNNN` oNNNm: sNNNh  +NNN/  mo       //
//      `dd  hNNN+  mNNN- +NNNN+ `NNNm` :NNNo  hNNNNNNNNNNNNNNNN/ `mNNN- /mNNN` oNNNm: sNNNh  +NNN/  mm-      //
//      :Nd  hNNN+  mNNN- +NNNN+ `NNNm` :NNNo  /oooooooooooooooo- `mNNN- /mNNN` oNNNm: sNNNh  +NNN/  mNo      //
//      +Nd  hNNN+  mNNN- +NNNN+ `NNNm` :NNNs`````````````````````.mNNN- /mNNN` oNNNm: sNNNh  +NNN/  mNy      //
//      +Nd  hNNN+  mNNN- +NNNN+ `NNNm` :NNNmmmmmmmmmmmmmmmmmmmmmmmNNNN- /mNNN` oNNNm: sNNNh  +NNN/  mNy      //
//      +Nd  hNNN+  mNNN- +NNNN+ `NNNm` :dddddddddddddddddddddddddddddd- /mNNN` oNNNm: sNNNh  +NNN/  mNy      //
//      +Nd  hNNN+  mNNN- +NNNN+ `NNNm`  ``````````````````````````````  /mNNN` oNNNm: sNNNh  +NNN/  mNy      //
//      +Nd  hNNN+  mNNN- +NNNN+ `NNNmhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdNNNN` sNNNm: sNNNh  +NNN/  mNy      //
//      +Nd  hNNN+  mNNN- +NNNN+ `NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN` sNNNm: sNNNh  +NNN/  mNy      //
//      +Nd  hNNN+  mNNN- +NNNN+  oooooooooooooooooooooooooooooooooooooooooooo  oNNNm: sNNNh  +NNN/  mNy      //
//      +Nd  hNNN+  mNNN- +NNNNy++++++++++++++++++++++++++++++++++++++++++++++++hNNNm: sNNNh  +NNN/  mNy      //
//      +Nd  hNNN+  mNNN- +NNNNNNNNNNNNNNNNNNNNNNNNHYPERREALNNNNNNNNNNNNNNNNNNNNNNNNm: sNNNh  +NNN/  mNy      //
//      +Nd  hNNN+  mNNN- +NNNNmddddddddddddddddddddddddddddddddddddddddddddddddmNNNm: sNNNh  +NNN/  mNy      //
//      +Nd  hNNN+  mNNN- +NNNNo..--------------------------------------------..yNNNm: sNNNh  +NNN/  mNy      //
//      +Nd  hNNN+  mNNN- +NNNN+ `yhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhy` oNNNm: sNNNh  +NNN/  mNy      //
//      +Nd  hNNN+  mNNN- +NNNN+ `NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN` oNNNm: sNNNh  oNNN/  mNy      //
//      +Nd  hNNN+  mNNN- +NNNN+ `NNNmooooooooooooooooooooooooooooooooooohmNNN` sNNNm: sNNNh  +NNN/  mNy      //
//      +Nd  hNNN+  mNNN- +NNNN+ `NNNm` `:::::::::::::::::::::::::::::-` +mNNN` sNNNm: sNNNh  oNNN/  mNy      //
//      +Nd  hNNN+  mNNN- +NNNNo `NNNm` :mmmmmmmmmmmmmmmmmmmmmmmmmmmmmm- +mNNN` sNNNm: sNNNh  +NNN/  mNy      //
//      +Nd  hNNN+  mNNN- +NNNNo `NNNm` :NNNmhhhhhhhhhhhhhhhhhhhhhdNNNN- /mNNN` sNNNm: sNNNh  +NNN/  mNy      //
//      +Nd  hNNN+  mNNN- +NNNN+ `NNNm` :NNNo                     `mNNN- /mNNN` sNNNm: sNNNh  oNNN/  mNy      //
//      +Nd  hNNN+  mNNN- +NNNN+ `NNNm` :NNNo  oyyyyyyyyyyyyyyyy: `mNNN- +mNNN` sNNNm: sNNNh  oNNN/  mNy      //
//      :Nd  hNNN+  mNNN- +NNNN+ `NNNm` :NNNo  hNNNNmmmmmmmmNNNN/ `mNNN- /mNNN` sNNNm: sNNNh  oNNN/  mNo      //
//      `dd  hNNN+  mNNN- +NNNNo `NNNm` :NNNo  hNNm-````````/NNN/ `mNNN- /mNNN` sNNNm: sNNNh  oNNN/  mm.      //
//       -d  hNNN+  mNNN- +NNNNo `NNNm` :NNNo  hNNm.  -//-  :NNN/ `mNNN- +mNNN` sNNNm: sNNNh  +NNN/  m+       //
//        -  hNNN+  mNNN- +NNNNo `NNNm` :NNNo  hNNm.  smmo  :NNN/ `mNNN- +mNNN` sNNNm: sNNNh  +NNN/  +        //
//           hNNN+  mNNN- +NNNNo `NNNm` :NNNo  hNNm.  sNNo  :NNN/ `mNNN- +mNNN` sNNNm: sNNNh  oNNN/           //
//           /dNN+  mNNN- +NNNN+ `NNNm` :NNNo  hNNm.  sNNo  :NNN/ `mNNN- /mNNN` sNNNm: sNNNh  oNNm-           //
//            ./y/  mNNN- +NNNN+ `NNNm` :NNNo  hNNm.  sNNo  :NNN/ `mNNN- +mNNN` sNNNm: sNNNh  +ho.            //
//              ``  hNNN- +NNNN+ `NNNm` :NNNo  hNNm.  sNNo  :NNN/ `mNNN- +mNNN` sNNNm: sNNNy  ``              //
//                  `-oh- +NNNN+ `NNNm` :NNNo  hNNm.  sNNo  :NNN/ `mNNN- +mNNN` sNNNm: shs:`                  //
//                     `  /dNNN+ `NNNm` :NNNo  hNNm.  sNNo  :NNN/ `mNNN- +mNNN` sNNNd- .`                     //
//                         ./sd/ .NNNm` :NNNo  hNNm.  sNNo  :NNN/ `mNNN- +mNNN` ody/.                         //
//                            `` `dmNm` :NNNo  hNNm.  sNNo  :NNN/ `mNNN- +mNmd` ..                            //
//                                ..+s` :NNNo  hNNm.  sNNo  :NNN/ `mNNN- /y+-.                                //
//                                      :mNNo  hNNm.  sNNo  :NNN/ `mNNm/ `                                    //
//                                       -/y+  hNNm.  sNNo  :NNN/ `dh+-`                                      //
//                                             ymNm.  sNNo  :NNm/  .                                          //
//                                              -/o`  ommo  -s+-`                                             //
//                                                     ``                                                     //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PCM is ERC721Creator {
    constructor() ERC721Creator("POETRY CARDS VOL 1 | META/VERSE", "PCM") {}
}