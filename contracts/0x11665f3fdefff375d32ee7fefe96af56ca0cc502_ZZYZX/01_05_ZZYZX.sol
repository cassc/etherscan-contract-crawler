// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ZZYZX by Gregory Halpern
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                -+++++++++++/               .+++   -++/                                                  .+++           -+++                                  //
//                sMMMMMMMMMMMm               /MMM`  sMMm                                                  /MMM`          +MMM                                  //
//                sMMM.........    `-:::-`    /MMM`  sMMm      .::::.    `---`   .--.   `---    .::::-`    /MMM``-::-`    .:::   .--` .::-`                     //
//                sMMM           :hNNMNMNmy.  /MMM`  sMMm   `omNNMMMNmo` `mNNs  `NNNm   sNNh  /dNNmmNNms`  /MMMyNNMMNmo   /NNN   dNNsdNNMNNh:                   //
//                sMMMmddddddy  +NMN+..-sMMN- /MMM`  sMMm  `dMMd/../dMMd` +MMN` +MNMM/ `NMM: -MMM/.`-hdd+  /MMMh:..sMMM:  +MMM   dMMNs:-/hMMN:                  //
//                sMMMhhhhhhhs  NMMdoooooNMMy /MMM`  sMMm  oMMM`    `MMMo  mMM+ mMohMd oMMy  .NMMNdhso/-`  /MMM.   .MMM/  +MMM   dMMs    `mMMh                  //
//                sMMM`         MMMdyyyyyyyy+ /MMM`  sMMm  sMMN      NMMs  :MMm:MM.:MM-mMN.   .+shdmMMMmo  /MMM`   `MMM/  +MMM   dMM+     dMMh                  //
//                sMMM          yMMd.   -ooo- /MMM`  sMMm  -NMMo.  .oMMN-   hMMmMy  mMmMMo   +yys``.-yMMM` /MMM`   `MMM/  +MMM   dMMm-` `+MMM/                  //
//                sMMM          `smMNdhdNMms` /MMM`  sMMm   :dMMmddmMMd:    -MMMM-  +MMMm`   -dMMmhhhNMNo  /MMM`   `MMM/  +MMM   dMMmmmdmMMm+                   //
//                -///            .:osyso:.   .///   -///    `-+ssss+-`      ////   `///-     `-+ssyso/.   .///    `///.  .///   dMMo-+oso:.                    //
//                                                                                                                               dMMo                           //
//                                                                                                                               hmm+                           //
//                                                                                                                               ````                           //
//                                                                                                                                                              //
//                `.:/+/-`                                                          .-.    .-.           --                                                     //
//               :hNmyyhNm+      `    ``       ``        ```        `               hMh    hMy    ```   .MM`     ``      ```        `     ``                    //
//              -NMo`   :ss` +h+sd:`+hhhhs. `+hhhssh: `/yhhhy:  +h+sd:yh+  -hy`     hMh....dMy `+hhhhy- .MM` ohoyhdy:  -shhhy/  yh/yd`+hoshdh+                  //
//              oMM   :ssss. yMN+:.hMh::oMN.sMd:-/MM+ sMd-.:mM+ yMN+:./MN. hMo      hMNddddNMy -yy::hMh .MM` dMd:-/MM::NN+:/mMo mMd/: sMm:./MM.                 //
//              /MM-  :+oMM: yMy   MMhyyyhh-mMo   mM+ NM+   yMd yMy    yMy:Md       hMh````dMy -hdyydMd .MM` dM+   mMosMNyyyhhs mM+   sMy  `MM-                 //
//               sNms/:+dNM: yMy   yMh:-+ys`+NN+/sMM+ oMm/-/NN/ yMy    `mMmN.       hMh    hMy hMy.-hMd .MM` hMd:-oMN--NN/-:yy: mM/   sMy  `MM-                 //
//                -oyhhs::s. /s/    :shhy+. `:sss/mM/  :shhyo-  /s/     :MM+        /s+    +s/ .shyo/so``ss` hMsshho.  .+yhhs:  os-   /s/  `ss.                 //
//                                          :ddsoyNd`                  shNy                                  hM+                                                //
//                                           `://:-                    :/-                                   -:.                                                //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ZZYZX is ERC721Creator {
    constructor() ERC721Creator("ZZYZX by Gregory Halpern", "ZZYZX") {}
}