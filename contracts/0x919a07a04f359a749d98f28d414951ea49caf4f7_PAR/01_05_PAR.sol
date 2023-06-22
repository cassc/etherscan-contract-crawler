// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Parished
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                             //
//                                                                                                                                                                             //
//                                                                                                                                                                             //
//                                                                                                                                                                             //
//                         ``                                                                                                                                                  //
//                `.      /.                                                                                                                                                   //
//                 `//` -s.                             `.`    ``                                                                                                              //
//                   -ysm/:----.``                        .//-:.                                                                                                               //
//             ``.-:/+odh-```                           `-::so.                                                                                                                //
//              ``     .m.-.                               `-``                                                                                                                //
//                      /o ./-                             :`                                                                                                                  //
//                       s`  -+-                  .  `     +                                                                                                                   //
//                       `/   `/o-        `       .o+`     s                                                                                                                   //
//                        .     .oo-       .      `.+`    .s                                                                                                                   //
//                                -ss.      -       /     +/              `                                                                                                    //
//                                  :hs.    `:      /:    h-          `: `:               `.``:                                                                                //
//                                   `+ds.   `/   ` `h   `N`  `:.   ```+so-`               .sh:                                                                                //
//                                 :. `:sms.  .+  :  h-  :m   :+` `..-:+my:-`          `-.`.- -.                                                                               //
//             `         ``..       syo` .yNo. -+ :-`oh  sy  -y      -o-o`         `-/:-                                                                                       //
//             /            `-::-``---s/:. :dNo`:+`h./M. mo -N-    :ho  `       ./+/.                                                                                          //
//             s                ./+o/` ` -+o-/mNoooy+yNy-M:-Nh   /dd-       `:ss/`                                                                                             //
//             o: `---.             -oys+. `+hydMNNhNsNMyM/NM- +mMo   `  -ohs/`               .                                                                                //
//       `.-:/+hms+.                   `:sdh+:/yMMMMMdMMMMNMdoNMd..//+ohds:                  `/                                                                                //
//            .hoso+-:::////:-.`      `-:///shmdymMMMMMMMMMMMMMmymmdmmy/:::://::-.`          o-                                                                                //
//           -+`  `-/:-` ``.:/osyyyyso+/::/+shmMMMMMMMMMMMMMMMMMMMMMNdhys+/:.```   `..--::///m//::-.                                                                           //
//          -.        `.`       ```.:/oyhdmNNmmmMMMMMMMMMMMMMMMMMMNddddhhhhhhyyyssoo+++///::yhh.`                                                                              //
//                                       ``.:+ydMMMMMMMMMMMMMMMNmhsoo+//:--..``````       .+- :o`                                                                              //
//                                 -:-.-/oyhmmNNMMMMMMMMMMMMMMMNNmmhyo/:-.`              .-`   `/`                                                                             //
//                              `.-+yyyhddddhhhmMmmmMMMMMMMMMMMNdyso+oossssso+/:-.``    ``       .                                                                             //
//                         `.-:::::---...`.:/ososdNMmMMMMMMMMmshNmssso/:-.```........`                                                                                         //
//                                     .:++/:/ydMMd/dMNMMMMMM+y/./y+.`.-----.`                                                                                                 //
//                                 .-//:-.-oyo+hh/`sMomMdMMMMo.oso:.-.                                                                                                         //
//                             ``-:-.` `//:..-s/` +Mo NM:mMoNd--.-.`  .-:/::::::.     ``.   :s `s:                                                                             //
//                     `` ```....     `.`+`-o:`  :No `MN`yM-/M.     -o+-`      `/-    `.:o:-m: sd::.                                                                           //
//                      +o/.`        ```.+dd-`  -No  .My /M` so   `ss`          `+        /Ny`/N.  .`                                                                          //
//                     `--:         `...--h/-.``ms   -M: .N  `y   ys           `o`        yh.+N+...`            .`          `--                                                //
//                                        /    hs    /N   y   .. `M/        `.//`        /N. hs-: `::.         /Nh         :dm/.                                               //
//                                            ss     +s  -y:     `Nd` -sssso+/`         `m+ +N/yy`dh-`        -NM-        oMd`-`                                               //
//                                           +s      s-  ..-      +Mm/`..`              +d /Mo+M:+m `.       `mM+        yMh` :                                                //
//                                          :s       o             /NMNy-               y:/-/`Ms: :-.        hMh        yMh` /                                                 //
//                                         .o        :              `+dMMd-             `-    s-            oMm`       yMd``/`                                                 //
//                                        `+         `             ``  /mMMo        ``                     -MM-  .`   oMm.--                                                   //
//                                    `  `/       ``         `:oo+/--:/:.dMMo     -:-m/        ``  `      `mM+`/oom` :Mm:.     `   `       `.     `.                           //
//                                     -+y`    -::--:::-`  .odo.`      o`-MMN  /mh- /Mh  .sm+//Ns /Ns     yMy:o--dN`.NM-    /ys:/ yN:       .+`  -/                            //
//                                    `-+/-.  ::`      `::oms.        .o  MMM .NMo .mMo /NM/ +MN.-Nm::`  /MNo-`+Nm: hMo   .dMo::`sMs-:   -:-.:s/+s`                            //
//                                      :     +/-       `hNo:.`    `-:/` -MMy`dMh``hMd`/NM+ /NM: /y+:Ns `mMs.:hd+` /Md   .mMy:`  sy:yN+ :.   `+hNo/:-..`                       //
//                                      `      -:       yN: `.-:::::.`  `dMh`yMd``yMm/-mMy -NMs -.  hMh sMhs//-`  .NM-  ./Mm`  `-` +MM/--  ./o-`y````````                      //
//                                                     .Mo             -dNs`+MN//hMy.` NM../Md`:-  +MM+.NNym     `yMy `-``ds `--  .NMh-: `::.   /.                             //
//                                                     -M-           .omy- :NN:ydh:    /y...N//-  .NMm`+-/+N    `+/M+--`  `::-`   +Md:/ ```     `-                             //
//                                                      ho        .:oy+.  .mM+ ``           ::.   yMM/:-  `N-  `+. :-`            -d+:           `                             //
//                                                      `//:---:///:.    `hMs                    `NMh.+    /o `/.                   `                                          //
//                                                          ````         sMd`  `-..              .MN-o`     ---`                                                               //
//                                                                      /MN.   ./y:               yy+`                                                                         //
//                                                                     -NM/    `- ``               `                                                                           //
//                                                                     dMy     `                                                                                               //
//                                                                     oN-                                                                                                     //
//                                                                                                                                                                             //
//                                                                                                                                                                             //
//                                                                                                                                                                             //
//                                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PAR is ERC721Creator {
    constructor() ERC721Creator("Parished", "PAR") {}
}