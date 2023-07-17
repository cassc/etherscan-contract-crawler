// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wonder Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    __      _____  _ __   __| | ___ _ __ _ __ ___  _   _ _ __   __| | ___                                   //
//     \ \ /\ / / _ \| '_ \ / _` |/ _ \ '__| '_ ` _ \| | | | '_ \ / _` |/ _ \                                 //
//      \ V  V / (_) | | | | (_| |  __/ |  | | | | | | |_| | | | | (_| | (_) |                                //
//       \_/\_/ \___/|_| |_|\__,_|\___|_|  |_| |_| |_|\__,_|_| |_|\__,_|\___/                                 //
//                                                                                                            //
//                                                                                                            //
//                                   `  `  `                        `  `                                      //
//             `  `                           `  `  `  `                         `  `  `  `                   //
//    `           `  `  `               `  `         `:/s:``  `  `  `  `                      `               //
//                                `  `  `.`.  ` -://-.--/+os+/. `       `  `  `  `  `                         //
//          `     `  `                .++:     `  .-+hddh++/+shy:`               `   `  `  `  `               //
//    `              `      `  `  ` .ss/s.        ` .:/oNNNNy:--+y+- `  `  `               `                  //
//          `                     /yhsys-   `     `  `::ohmddmmo-.oyy-     `      `  `  `                     //
//    `     `  `  `   `  `  `   `+dysh:` .     `  `  ``.++sddhdmdyo`-sy:`         `     `   `  `              //
//     `              `     `  /sysds``-:.  `            .///ydmmNdy/-:hy:` `  `            `  `              //
//          `              `.`smhym+``o- `  `         `  ` .o+ommNNdhh+`oho/`  `         `                    //
//      `   `      `  `  `.:-+Nhdm+./s-                     `.odmNmmNmmy:+hso-                  `             //
//      `                `/:+mmmN+-yd-`  `  `                 `+dNNmmNNNd+/sos+.                              //
//          `      `    `yo/mmmNs.dy-              `  `  `      -hmmmmNNNd++hoys.     `  `   `                //
//                 `  ` sd/mhmNy-dy:                            ``ohdshNmmms+s+ss-                            //
//                     /d/mNdNd/hy:`      `  `  `                  :hdsmmNmNh/y++o/`      `                   //
//           `  `  `  -m/dNmNNodh:/                `   `  `     `  `-ymhdmNNmdoss+ho`  `  `  `   `            //
//                    hysNNNNdhy+s- `  `  `  `            ` `   `    .hohomdmddddyhy/`                        //
//     `     `  `  ` :MomNNNNom-oy     `  `  `  `   ` -` `: `         .h/dddmmdmNmhm/.``      `               //
//           `  `  ` yNmNmMyhN+/h+  `   .``o        ` `. .:+ `      `  .h/mmhoyNNNmms.```  `                  //
//                  `NNsmhdmmm-os/  `  -so`      `       oo:        `  `-d+mNm+yNNNNN--`-                     //
//      `    `  `   :hdyoNsNN+.dh.     `dy`   `  `  `  `  ``  `  `       shdmmd/dNmmN//`.. `  `   `           //
//                  oyhdymsNN:omy.  `  `-`                    `  `  `    `mmNmNsyNNsN-o. :        `           //
//           `      ydyNdddNd-hdy`  `      `  `  .  `                     shNdN+dNhdNs-:`: `                  //
//      `    `      hhdNNNmNm/dos                .      `  `  `  `   `    -hmomhsmhhNN-s :  `  `              //
//                  hsyNMNdMm+s/o`  `   `  `    `.                   `  `  dd+mNymdhNN//-:                    //
//           `   `  sy:NmNyMNs+/+                /:. `  `  `               ymmmNNhmhmNo./:  `      `          //
//                  +m.myMhMNd//o`   `                         `  `  `  `  oNNdNNomoNNy.+`                    //
//               `  :d:ddMNMNm.+:.      `  `   `  `  `  `                  +NmNmN:N/Nm//y`      `  `          //
//               `  .d-mNNNMNd.+.:                   `  ``  `  `  `      ` /mNmmN+d+Nd`+:       `   `         //
//                   d-mhNNMNh`/ :`  `  `   `  ``.- ```.-             `  ` +smmmNNhyN+`o-    `                //
//            `  `  `yodymNMNN`: -`           -/o//.-//-o`  `  `      `    symmmNN+mN-``  `  `   `  `         //
//                   :sd/mNmMN-:. :  `  `   ` hhy++/o+/o.       `  ` ..  ``m/dNNNN/Nh                         //
//            `  `   `+y`mdhMN-`: `      `  ` `ohysyhy/  `          ..    //+hNNNNhN+  `  `   `  `            //
//               `   `/h.do-NMs-/ `  `           `..` `  `   `  `  .```   ./`oNyNdmN`                `        //
//                     h-ss sMm/+``      `  `  `   `              ::.  `  `/ yysddNy`  `   `  `               //
//            `  `   ` -y/h/.Nmm/-              `  `  `   `  `  -o-`       -`dsmdmN.       `      `  `        //
//      `               o.y.`oN+sy`   `  .` `                `::-`  `  `  `-:dNmhds `   `                     //
//            `   `  `  `+o` .mh.s+      `-/+/-..  `   `  `.::.o           -shNd+y-  `  `      `  `   `       //
//                `  `   -/`` -mo.ho```     `.-/so/:::----o+`  y/`  `  `   y:hm//d`                           //
//            `   `  `    -:   +Ns/y. `  `   `  :: .---:-..    /d`        `/``h`y/   `  ``  `  `   `          //
//                   `   ` `.  `yd+s.``  `      s+            `:Ny  `   `  `  +-s                             //
//                `         `   .h-:+ `   `  `  yh  `  `  `     dN.           o+` `   `  `  `   `  `          //
//             `  `  `   `  `   `/+.--`         +d.    `   `  ` -Ns  `  `  `  y:                       `      //
//                              ` .. `-`  `  `  -m: `            sd         ` /`  ``  `  `   `  `             //
//     `:.     `  `   `  `  `      `             m- `  ``  `  `  `h. `        -              `  `   `  `      //
//                       `   `  `  `   `  `  `   h`               .+ `   `  `  ``  `  `   `                   //
//             `  `   `                   `   `  /- `   `  `   `  `o`               ````  `  `   `  `   `     //
//                    `  `   `  `  ``  `  `      `.            `  `yy/oosyyyyyyyyyyyoyhho/.                   //
//             `                       `  ``.`       `  `  `      /om+++/:/:/oooso+++oshhddhs-`  `   `  `     //
//             `   `  `  `   `  `   .`..`.  `           `   `  ` -oh` `  `   `  `   ```.-:s++so:`             //
//                             `````..-` `     -`..  `         .-/+-         `      `  `   .`-+oh+-           //
//      `:+`   `   `  `   `  ....`  ``..`      :s/.  `      ``.:-o:.  `   `  `                 .-yds.    `    //
//      `o+`              `...``  `        `  ` `shs/:--//:``.:sy-        `      `  `   `  `   `  -/y/        //
//             ``  `  `  .:...                  ``:oyy+sdo::+ss:.  `   `  `      `                  `+/`      //
//       `.            .:.          .   ` `-`  ` ``  `-:++/-.``               `  ``  `  `   `  `      +:`     //
//             ``  `  -/`      `       `-...`    `    ` `-``.-  `  `   `  `   `         ``            .--`    //
//                   --        `--     +s.-`   `  -` `-/-.```              `  .  `.`.--.-`  `   `  `   :      //
//      .-     ``  `.-   .   `oo` `  .-:-.       --`-yh/`.`` .  `   `  `      `-...`` ``        `  ``  -      //
//                  :   -   /m+ .`  `. .-  `.  ..  -+/:`                 `.:-.``  `  ``  `  ``  `             //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract w0nders is ERC1155Creator {
    constructor() ERC1155Creator() {}
}