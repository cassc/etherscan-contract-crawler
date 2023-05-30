// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cath Simard Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMmymMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNho/:mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMyo/../NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNNNMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMdoo:...+mMMMMMMMMMMMMMMMMMMMMMMMMMMMNmmddddmmNMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNooo:....:dMMMMMMMMMMMMMMMMMMMMMMMMNmdyo/::/oydmNMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMdooo:.....-dMMMMMMMMMMMMMMMMMMMMMMNmds-      -sdmNMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNsooo-......-dMMMMMMMMMMMMMMMMMMMMMNmh:        +hmNMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMdoooo/........-hMMMMMMMMMMMMMMMMMMMMNmh+       `ohmNMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMdooooo/.........-yMMMMMMMMMMMMMMMMMMMMNmho-`  `-ohmNMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMdoooooo:...........+NMMMMMMMMMMMMMMMMMMMNNmdhyyhdmNNMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNoooooo+.............-yMMMMMMMMMMMMMMMMMMMMMNNNNNNMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMyooooooo-.............-sMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMmsoNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMhooooooo/...............-oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMdyy:+NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMmooooooooo:................/hMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMdyyy+-/NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMmoooooooooo:.................-oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMhyyyo--+mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNsooooooooo+....................oMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMNyyyyy/--/mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMyoooooooooo/.....................oMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMNhyyyyys:--/NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMmoooooooooo+-.....................-yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNhyyyyyyy+---oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNsoooooooooo:.......................-hdsdMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMhyyyyyyyyy+---/mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMyooooooooooo+.......................:ss::dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMmyyyyyyyyyyy+---:yMMMMMMMMMMMMMMMMMMMMMMMMMMMmooooooooooooo-.....................:yyo--:yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNhyyyyyyyyyyyy:----+NMMMMMMMMMMMMMMMMMMMMMMMMdooooooooooooo+-.....................syy:----+NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMyyyyyyyyyyyyyys:----:yNMMMMMMMMMMMMMMMMMMMMNyooooooooooooooo+-..................-oyy+------:odMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMmyyyyyyyyyyyyyyyy:-----:yMMMMMMMMMMMMMMMMMMdoooooooooooooooooo/..................+yyy+---------+NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNyyyyyyyyyyyyyyyyy:-------yMMMMMMMMMMMMMMMMhooooooooooooooooooo+.................+yyyy+----------:ymMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNyyyyyyyyyyyyyyyyys:-------:mMMMMMMMMMMMMMNhooooooooooooooooooooo/.............../yyyyyy/-----------:omMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMhyyyyyyyyyyyyyyyyyys+-------+NMMMMMMMMMMMmsoooooooooooooooooooooo/..............+yyyyyyyy/------------:sNMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMmyyyyyyyyyyyysyyyyyyyyo-------sMMMMMMMMMmhsooooooooooooooooooooooo/.............:yyyyyyyyyy/-------------/mMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMmyyyyyyyyyyyys/osyyyyyyyo:-----:sNMMMMMNyooooooooooooooooooooooooooo/-..........-syyyyyyyyyys:-------------:dMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMmyyyyyyyyyyyyh+///+syyyyyyy+:-----+NMMNdsooooooooooooooooooooooooooooo/-........-+yyyyyyyyyyyy+--------------:dMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMmyyyyyyyyyyyydy//////+syyyyyys------smhsoooooooooooooooooooooooooooooooo/.......-+yyyyyyyyyyyyys---------------:dMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMNyyyyyyyyyyyyhddo///////oyyyyyy:------+oooooooooooooooooooooooooooooooooo+.......+yyyyyyyyyyyyyyy+---------------/NMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMNyyyyyyyyyyyyydddds///////+syyyyy+:----:+ooooooooooooooooooooooooooooooooo+-.....:yyyyyyyyyyyyyyyyy+---------:-----oMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMNyyyyyyyyyyyyyhddddds////////oyyyyys:----:oooooooooooooooooooooooooooooooooo+-...-syyyyyyyyyyyyyyyyyy/-------/+//----hMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMmyyyyyyyyyyyyyyhdddddd/////////+syyyyy/----:oooooooooooooooooooooooooooooooooo/...oyyyyyyyyyyyyyyyyyyys:-----:hs///:--:mMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMmyyyyyyyyyyyyyyhddddddy///////////oyyyys:----/oooooooooooooooooooooooooooooooooo+/oyyyyyyyyyyyyyyyyyyyyys:---:ydds///:--:yMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMmyyyyyyyyyyyhhdddddddddd////////////+syyyy+:---+oooooooooooooooooooooooooooooooooyyyyyyyyyyyyyyyyyyyyyyyyys:-:hdddd////:---/hMMMMMMMMMMMMMMMMMM    //
//    MMMMMMmyyyyyyyyyyyhdddddddddddh//////////////+syyyso:--/oooooooooooooooooooooooooooooooyyyyyyyyyyyyyyyyyyyyyyyyyyys/oddddds////:----/hmMMMMMMMMMMMMMMM    //
//    MMMMMmyyyyyyyyyyyhddddddddddddds///////////////osyyyy/--:/+oooooooooooooooooooooooooosyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyhdddddds////:-----:odNMMMMMMMMMMMM    //
//    MMMNdyyyyyyyyyhddddddddddddddddds///////////////+oyyyy:---::+sssoooooooooooooooooooosyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyhddddddddo////:------:/ymMMMMMMMMMM    //
//    NNdhyyyyyyyyyhdddddddddddddddddddy+///////////////+syy/-:/+shhhh++++++oooooooooooosyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyydddddddddy//////--------:+sNMMMMMMM    //
//    hyyyyyyyyyyhddddddddddddddddddddddo/////////////////+yhshddddddy//////+oooooooooosyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyydddddddddds///////:---------/dMMMMMM    //
//    yyyyyyyyyyhdddddddddddddddddddddddh+//////////+o++sshddddddddddd+//////oooooooosyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyhdddddddddds////////::--------:sNMMMM    //
//    yyyyyyyyyhdddddddddddddddddddddddddy+/////////+hhddddddddddddddh+//+++/++oooosyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyhdddmmmmdddddy+/////////:--------+dNNM    //
//    yyyyyyyhddddddddddddddddddddddddddddho/////////oddddddddddddddd+///+hhyo+/+osyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyydddddmddddddddho//////////:--------+hN    //
//    yyyyhhddmMNmddddddddddddddddddddddddddo+++++++++hdddddddddddddh+++//ohddhs++/+oyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyhddddmmmdddddddddy+/////////:-:o:----:s    //
//    yyhddddNNMMNddddddddddddddddddddddddddh+++++++++sddddddddddddddy+++++sdddddhyo++osyyyyyyyyyyyyyyyyyddyyyyyyyyyhdddmmmmmmdddddddddh+/////////:+mo-----:    //
//    NNdddddNMMMMNddddddddddddddddddddddddddo+++++++++yddddddddddddddds++++hdddddddhy+/oyyyyyyyyyyyyyyyymmhyyyyyyyhdddddmdmmmddddddddddh+++///////smh:-:--:    //
//    MMMddddmMMMMNddddddddddddddddddddddddddhoooooooooohmmmmmddddddddddds++odddddddddmd+/+oshyyyyyyyyyyhmmhyyyyyydddddmmdmmmmmmdddddddddhmd+////++dmd:oh/:y    //
//    MMMNddNMMMMMNdddddddddddddddddddddmmmmmmhoooooossssdmmmmmmmmmmmmmmNmho+smdddddddmmdyo+sd++oosyyyyyhmddyyyyydddddmmmmmNmmmmdddddddddmmmho+++yshmdosds/d    //
//    MMMMNmMMMMMMmmmdddddmmmmmmmmmmmmmmmmmmmmmdssssssssyymmmmmmmmmmmmmNNNmdhdmmdddddmmmmdddmmso+oyoshyhddmhydyydddddddmmmNNmmmmmmdddddddmNNmmds+dddmmyhdhhd    //
//    MMMMMmmMMMNMMNmmmmmmmmmmmmmmmmmmmmmmmmmmmmdyyyyyyyhhhNNNNNNmmmmmNNNNNmmNNmdddddmNNmdddmmddddmddddmdmddhmddddmdddddmNNNmmmmmdddddddmmNNNMMNyNNmmmdhddhd    //
//    MMMMMNmMMMMMMNNmmmmmmmmmmmmmmmmmmNNNNNNNNNNhhhhdddddmNMNNNNNNNNNNNNNNmNNNNmmddmmmNmmmmmmmmdmmmdddmmmddmmmddmNmddddmmmMMNmdddmdmdNNNNNNNMMMmMNmmNmdddos    //
//    MMMMMMNMMMMNNNmmmmmmmmNNNNNNNNNNNNNNNNNNNNmddmmmmmmmNMMMNNMMNNNNNMMMNNNNNNNmmmmNNNNNNNNNNNNmmmmddmmdddmmmmmMNmmmmmmmMMMMNmmmNmNNMMMNNNNMMMMMMNNNmddhyo    //
//    MMMMMMMMMMMMMNNNNNNNNNNNNmhyo+/////+oydmMMmmNNNNNNNNMMMMhsssssssssNMMNNNNmsssssssssssssssssssssoooosmmmsssssssshNNNMMMMMMooossssshMMNNMMMMMMMNdddhhhhs    //
//    MMMMMMMMMMMMMNNNNNNNNNmy:.`           `./hNNNNNNMMMMMMMd`         +MMMMMMh                         `NNN        /MNMMMMMMM        /MMMNMMMMMMMMddddmNNN    //
//    MMMMMMMMMMMMMMMMMMMMNs.                   :dMMMMMMMMMMN-           yMMMMMh                         `NMM        /MMMMMMMMN        /MMMNMMMMMMMMNNNNNNNN    //
//    MMMMMMMMMMMMMMMMMMMN/        `.-::.`       `dMMMMMMMMM+            `mMMMMd````````         ````````.NMM        /MMMMMMMMM        /MMMMMMMMMMMMMMMNNNNM    //
//    MMMMMMMMMMMMMMMMMMM+        :hNMMMMm+     ``-NMMMMMMMh      `-      :MMMMNdhhhhhhd/        shdddddhhNMM        /MMMMMMMMM        /MMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMm        :MMMMMMMMMs/oyhdNMMMMMMMMN`      od       oMMMMMMMMNNMMo        dMMMMMMMNMMM        -yyyyyyyyy        /MMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMs        hMMMMMMMMMMMMMMMMMMMMMMMM:      .MM/       dMMMMMMMMNMMo        mMMMMMMMNNMM                          /MMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMM+        NMMMMMMMMMMMMMMMMMMMMMMMo       hMMN`      .NMMMMMMMMMMo        mMMMMMMMMMMM                          /MMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMo        mMMMMMMMMMMMMMMMMMMMMMMd       :MMMMs       /MMMMMMMMMMo        mMMMMMMMMMMM                          /MMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMh        yMMMMMMMMMd-/oydNMMMMMN.       /sssso        sMMMMMMMMMo        mMMMMMMMMMMM        :ddddddddd        /MMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMM.       -NMMMMMMMm.    ``.dMMM/                      `mMMMMMMMMo        mMMMMMMMMMMM        /MMMMMMMMM        /MMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMd`       .sdmmmho.       -NMMy                        -NMMMMMMMo        mMMMMMMMMMMM        /MMMMMMMMM        /MMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMd.        `````        :mMMm`       ::::::::::`       +MMMMMMMo        mMMMMMMMMMMM        /MMMMMMMMM        /MMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMNo.                 .oNMMN-       :MMMMMMMMMM+        hMMMMMMo        mMMMMMMMMMMM        /MMMMMMMMM        /MMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMmy/-.``      `../ymMMMMs```````.dMMMMMMMMMMN.```````-NMMMMMs````````mMMMMMMMMMMM.```````+MMMMMMMMM.```````/MMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMmddhhhhhhdmNMMMMMMMmmmmmmmmmMMMMMMMMMMMMmmmmmmmmmNMMMMMNmmmmmmmmMMMMMMMMMMMMmmmmmmmmNMMMMMMMMMmmmmmmmmNMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CATH is ERC1155Creator {
    constructor() ERC1155Creator() {}
}